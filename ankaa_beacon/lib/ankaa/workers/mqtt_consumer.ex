defmodule Ankaa.Workers.MqttConsumer do
  @moduledoc """
  Consumes messages from MQTT broker and processes them.
  """
  use GenServer
  require Logger

  # Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Server Callbacks
  @impl true
  def init(opts) do
    test_mode = Keyword.get(opts, :test_mode, false)
    force_error = Keyword.get(opts, :force_error, false)

    state = %{
      client: nil,
      test_mode: test_mode
    }

    if not test_mode do
      if force_error do
        {:error, :connection_failed}
      else
        # TODO: Implement actual MQTT connection
        {:ok, state}
      end
    else
      {:ok, state}
    end
  end

  @impl true
  def handle_call({:test_handle_info, message}, _from, state) do
    case handle_info(message, state) do
      {:noreply, new_state} -> {:reply, {:noreply, new_state}, new_state}
      other -> {:reply, other, state}
    end
  end

  @impl true
  def handle_info({:publish, %{topic: topic, payload: payload}}, state) do
    payload = Jason.decode!(payload)
    _ = process_message(topic, payload)
    {:noreply, state}
  end

  @impl true
  def handle_info({:disconnect, reason}, state) do
    Logger.warning("MQTT client disconnected: #{inspect(reason)}")
    {:noreply, state}
  end

  @impl true
  def handle_info({:connect}, state) do
    Logger.info("MQTT client connected")
    {:noreply, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.warning("Unhandled message: #{inspect(msg)}")
    {:noreply, state}
  end

  @doc """
  Process an MQTT message based on its topic and payload.
  """
  def process_message(topic, payload) when is_map(payload) do
    case payload do
      %{"type" => "blood_pressure"} ->
        Logger.info("Processing blood pressure reading from #{topic}")
        # TODO: Implement blood pressure reading storage
        :ok

      %{"type" => "dialysis"} ->
        Logger.info("Processing dialysis reading from #{topic}")
        # TODO: Implement dialysis reading storage
        :ok

      %{"type" => type} ->
        Logger.warning("Unknown device type: #{type}")
        {:error, :unknown_device_type}
    end
  end

  # TODO: Implement actual MQTT connection
  defp connect do
    :ok
  end
end
