defmodule Ankaa.Monitoring.DeviceServer do
  use GenServer
  require Logger

  def start_link(device_id) do
    GenServer.start_link(__MODULE__, device_id, name: via_tuple(device_id))
  end

  def handle_reading(device_id, payload) do
    GenServer.cast(via_tuple(device_id), {:new_reading, payload})
  end

  @impl true
  def init(device_id) do
    {:ok, %{device_id: device_id}}
  end

  @impl true
  def handle_cast({:new_reading, payload}, state) do
    device_id = state.device_id
    Logger.info("[DeviceServer #{device_id}] Processing new reading.")

    # 1. Decode and process the data (add your BP/Dialysis structs here)
    data = Jason.decode!(payload)

    Logger.info("[DeviceServer #{device_id}] Received data: #{inspect(data)}")

    # 2. Check for threshold violations
    # violations = YourThresholdChecker.check(data)

    # 3. If violations, create alerts
    # if !Enum.empty?(violations) do
    #   Alerts.broadcast_device_alerts(device_id, data, violations)
    # end

    # 4. Asynchronously save the reading to the database (the "Scribe")
    # Task.start(fn -> Ankaa.Monitoring.save_reading(data) end)

    # 5. Broadcast to the LiveView UI for real-time updates
    # Phoenix.PubSub.broadcast(Ankaa.PubSub, "topic_for_ui", {:new_reading, data})

    {:noreply, state}
  end

  defp via_tuple(device_id), do: {:via, Registry, {Ankaa.Monitoring.DeviceRegistry, device_id}}
end
