defmodule Ankaa.Workers.MQTTConsumer do
  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    Logger.info("MQTTConsumer: Initializing and connecting to broker...")

    # Call the helper function to get the correct options for the environment
    opts = client_options()

    {:ok, client} = :emqtt.start_link(opts)

    case :emqtt.connect(client) do
      {:ok, _properties} ->
        Logger.info("MQTTConsumer: Successfully connected to broker!")
        :emqtt.subscribe(client, [{"devices/+/telemetry", 0}])
        {:ok, %{client: client}}

      {:error, reason} ->
        Logger.error("MQTTConsumer: Failed to connect: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_info({:publish, %{topic: topic, payload: payload}}, state) do
    topic_str = to_string(topic)
    [_, device_id, _] = String.split(topic_str, "/")

    case Ankaa.Monitoring.DeviceServer.start_link(device_id) do
      {:ok, _pid} ->
        :ok
      {:error, {:already_started, _pid}} ->
        :ok
      {:error, reason} ->
        Logger.error("Failed to start DeviceServer for #{device_id}: #{inspect(reason)}")
    end

    Ankaa.Monitoring.DeviceServer.handle_reading(device_id, payload)
    {:noreply, state}
  end

  @impl true
  def handle_info({:disconnected, reason}, state) do
    Logger.warning("MQTTConsumer: Disconnected from broker: #{inspect(reason)}")
    {:noreply, state}
  end

  # This is the helper function that reads from your config files
  defp client_options do
    mqtt_config = Application.get_env(:ankaa, :mqtt, [])
    client_id = "ankaa_consumer_#{System.unique_integer([:positive])}"

    [
      host: Keyword.get(mqtt_config, :host, "localhost") |> to_charlist(),
      port: Keyword.get(mqtt_config, :port, 1883),
      clientid: String.to_charlist(client_id),
      username: Keyword.get(mqtt_config, :username, "") |> to_charlist(),
      password: Keyword.get(mqtt_config, :password, "") |> to_charlist(),
      enable_ssl: Keyword.get(mqtt_config, :enable_ssl, false),
      ssl_opts: Keyword.get(mqtt_config, :ssl_options, [])
    ]
  end
end
