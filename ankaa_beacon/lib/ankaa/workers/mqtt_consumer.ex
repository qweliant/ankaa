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
    Logger.info("MQTTConsumer: Client options: #{inspect(client_options())}")
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
  def handle_info({:connected, _reason}, state) do
    Logger.info("MQTTConsumer: Successfully connected and ready!")
    {:noreply, state}
  end

  @impl true
  def handle_info({:publish, %{topic: topic, payload: payload}}, state) do
    topic_str = to_string(topic)
    [_, device_uuid, _] = String.split(topic_str, "/")

    case Registry.lookup(Ankaa.Monitoring.DeviceRegistry, device_uuid) do
      [{pid, _}] ->
        Ankaa.Monitoring.DeviceServer.handle_reading(pid, payload)

      [] ->
        case Ankaa.Devices.get_device(device_uuid) do
          %Ankaa.Patients.Device{} = device ->
            case DynamicSupervisor.start_child(
                   Ankaa.Monitoring.DeviceSupervisor,
                   {Ankaa.Monitoring.DeviceServer, device}
                 ) do
              {:ok, _pid} ->
                Ankaa.Monitoring.DeviceServer.handle_reading(device_uuid, payload)

              {:error, {:already_started, _pid}} ->
                Ankaa.Monitoring.DeviceServer.handle_reading(device_uuid, payload)

              {:error, reason} ->
                Logger.error("Failed to start worker: #{inspect(reason)}")
            end

          nil ->
            Logger.warning("Ignoring message for unregistered device: #{device_uuid}")
        end
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

    host = Keyword.get(mqtt_config, :host, "localhost")
    port = Keyword.get(mqtt_config, :port, 1883)
    port = if is_binary(port), do: String.to_integer(port), else: port
    client_id = "ankaa_consumer_#{System.unique_integer([:positive])}"
    username = Keyword.get(mqtt_config, :username, "")
    password = Keyword.get(mqtt_config, :password, "")
    ssl_enabled = Keyword.get(mqtt_config, :enable_ssl, false)

    [
      name: :emqtt_client,
      host: String.to_charlist(host),
      port: port,
      clientid: String.to_charlist(client_id),
      username: String.to_charlist(username),
      password: String.to_charlist(password),
      ssl: ssl_enabled,
      ssl_opts: [
        verify: :verify_none,
        server_name_indication: String.to_charlist(host),
        cacertfile: CAStore.file_path()
      ],
      reconnect: true,
      reconnect_interval: 10_000
    ]
  end
end
