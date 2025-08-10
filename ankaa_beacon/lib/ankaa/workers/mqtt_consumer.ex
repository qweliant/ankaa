defmodule Ankaa.Workers.MQTTConsumer do
  use Supervisor
  require Logger

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      %{id: :emqtt_client, start: {:emqtt, :start_link, [client_options()]}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def on_connect(client, _connack) do
    Logger.info("MQTT Dispatcher: Connected. Subscribing to device topics...")
    :emqtt.subscribe(client, [{"devices/+/telemetry", 0}])
  end

  def on_publish(_client, %{topic: topic, payload: payload}) do
    topic_str = to_string(topic)
    [_, device_id, _] = String.split(topic_str, "/")
    {:ok, _pid} = Ankaa.Monitoring.DeviceServer.start_link(device_id)
    Ankaa.Monitoring.DeviceServer.handle_reading(device_id, payload)
  end

  defp client_options do
    mqtt_config = Application.get_env(:ankaa, :mqtt)
    client_id = "ankaa_consumer_#{System.unique_integer([:positive])}"

    [
      name: :emqtt_client,
      host: Keyword.get(mqtt_config, :host, "localhost") |> to_charlist(),
      port: Keyword.get(mqtt_config, :port, 1883),
      clientid: String.to_charlist(client_id),
      username: Keyword.get(mqtt_config, :username) |> to_charlist_or_nil(),
      password: Keyword.get(mqtt_config, :password) |> to_charlist_or_nil(),
      conn_mod: __MODULE__,
      ssl_opts: Keyword.get(mqtt_config, :ssl_options, [])
    ]
  end

  defp to_charlist_or_nil(nil), do: nil
  defp to_charlist_or_nil(binary), do: String.to_charlist(binary)
end
