defmodule Ankaa.MQTT do
  require Logger

  @doc """
  Publishes a message to a given MQTT topic.
  """
  def publish(topic, payload) do
    case Process.whereis(:emqtt_client) do
      nil ->
        Logger.error("MQTT.publish: Could not find a running :emqtt_client process.")
        {:error, :not_started}

      client_pid ->
        Logger.info("MQTT.publish: Sending message to topic '#{topic}'")
        :emqtt.publish(client_pid, topic, payload)
    end
  end
end
