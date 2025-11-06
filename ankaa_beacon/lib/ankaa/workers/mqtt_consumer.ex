defmodule Ankaa.Workers.MQTTConsumer do
  @moduledoc """
  An MQTT consumer that connects to the broker, subscribes to device telemetry topics,
  and dispatches incoming messages to the appropriate device processes.
  """
  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    Logger.info("MQTTConsumer: Initializing...")
    # Start the client process but don't connect yet.
    {:ok, client} = :emqtt.start_link(client_options())

    # Send a message to ourself to trigger the connection attempt.
    # This makes the init function non-blocking.
    send(self(), :connect)

    {:ok, %{client: client}}
  end

  @impl true
  def handle_info(:connect, state) do
    Logger.info("MQTTConsumer: Attempting to connect to broker...")

    case :emqtt.connect(state.client) do
      {:ok, _properties} ->
        Logger.info("MQTTConsumer: Successfully connected to broker!")
        :emqtt.subscribe(state.client, [{"devices/+/telemetry", 0}])

      {:error, reason} ->
        Logger.error("MQTTConsumer: Failed to connect on first attempt: #{inspect(reason)}")
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:publish, %{topic: topic, payload: payload}}, state) do
    topic_str = to_string(topic)
    [_, device_uuid, _] = String.split(topic_str, "/")

    case Ankaa.Devices.get_device(device_uuid) do
      %Ankaa.Patients.Device{} = device ->
        case Ankaa.Monitoring.DeviceServer.start_link(device) do
          {:ok, _} -> :ok
          {:error, {:already_started, _}} -> :ok
          {:error, reason} -> Logger.error("Failed to start DeviceServer: #{inspect(reason)}")
        end

        Ankaa.Monitoring.DeviceServer.handle_reading(device.id, payload)

      nil ->
        Logger.warning("Ignoring message for unregistered device: #{device_uuid}")
        :ok
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:disconnected, reason}, state) do
    Logger.warning("MQTTConsumer: Disconnected from broker: #{inspect(reason)}")
    {:noreply, state}
  end

  def on_publish(_client, %{topic: topic, payload: payload}) do
    topic_str = to_string(topic)
    [_, device_uuid, _] = String.split(topic_str, "/")

    # 1. Find the full Device struct in the database using its UUID.
    case Ankaa.Devices.get_device!(device_uuid) do
      %Ankaa.Patients.Device{} = device ->
        # 2. Find-or-start the specialist process, passing the whole struct.
        {:ok, _pid} = Ankaa.Monitoring.DeviceServer.start_link(device)

        # 3. Dispatch the message to the specialist.
        Ankaa.Monitoring.DeviceServer.handle_reading(device.id, payload)

      nil ->
        # No patient has registered this device. Ignore the message.
        Logger.warning("Received message for unregistered device: #{device_uuid}")
        :ok
    end
  end

  defp client_options do
    mqtt_config = Application.get_env(:ankaa, :mqtt, [])
    client_id = "ankaa_consumer_#{System.unique_integer([:positive])}"

    port = Keyword.get(mqtt_config, :port, 1883)
    port = if is_binary(port), do: String.to_integer(port), else: port

    [
      name: :emqtt_client,
      host: Keyword.get(mqtt_config, :host, "localhost") |> to_charlist(),
      port: port,
      clientid: String.to_charlist(client_id),
      username: Keyword.get(mqtt_config, :username, "") |> to_charlist(),
      password: Keyword.get(mqtt_config, :password, "") |> to_charlist(),
      conn_mod: __MODULE__,
      enable_ssl: Keyword.get(mqtt_config, :enable_ssl, false),
      ssl_opts: Keyword.get(mqtt_config, :ssl_options, [])
    ]
  end
end
