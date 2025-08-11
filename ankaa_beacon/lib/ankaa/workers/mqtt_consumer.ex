defmodule Ankaa.Workers.MQTTConsumer do
  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    Logger.info("MQTTConsumer: Initializing and connecting to broker...")
    client_id = "ankaa_consumer_#{System.unique_integer([:positive])}"

    opts = [
      host: "localhost",
      port: 1883,
      clientid: String.to_charlist(client_id),
      clean_start: true,
      keepalive: 60,
      proto_ver: :v5
    ]

    {:ok, client} = :emqtt.start_link(opts)

    case :emqtt.connect(client) do
      # Match the {:ok, properties} tuple for a successful connection
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
    Logger.debug("MQTTConsumer: Received message on topic '#{topic_str}'")

    [_, device_id, _] = String.split(topic_str, "/")

    # Ensure a specialist process is running for this device.
    # We gracefully handle the case where it's already started.
    case Ankaa.Monitoring.DeviceServer.start_link(device_id) do
      {:ok, _pid} ->
        # Process started successfully for the first time.
        :ok

      {:error, {:already_started, _pid}} ->
        # Process was already running, which is the normal case.
        :ok

      {:error, reason} ->
        # Some other error happened during start, log it.
        Logger.error("Failed to start DeviceServer for #{device_id}: #{inspect(reason)}")
    end

    # Now that we know the process is running, dispatch the message to it.
    Ankaa.Monitoring.DeviceServer.handle_reading(device_id, payload)

    {:noreply, state}
  end

  @impl true
  def handle_info({:disconnected, reason}, state) do
    Logger.warning("MQTTConsumer: Disconnected from broker: #{inspect(reason)}")
    {:noreply, state}
  end
end
