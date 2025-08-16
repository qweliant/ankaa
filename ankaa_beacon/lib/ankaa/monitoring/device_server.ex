defmodule Ankaa.Monitoring.DeviceServer do
  use GenServer
  require Logger

  def start_link(%Ankaa.Patients.Device{} = device) do
    GenServer.start_link(__MODULE__, device, name: via_tuple(device.id))
  end

  def handle_reading(device_id, payload) do
    GenServer.cast(via_tuple(device_id), {:new_reading, payload})
  end

  @impl true
  def init(%Ankaa.Patients.Device{} = device) do
    patient = Ankaa.Patients.get_patient!(device.patient_id)
    {:ok, %{device: device, patient: patient}}
  end

  @impl true
  def handle_cast({:new_reading, payload}, state) do
    %{device: device, patient: _patient} = state
    Logger.info("[DeviceServer #{device.id}] Processing new reading.")

    # 1. Decode and process the data (add your BP/Dialysis structs here)
    data = Jason.decode!(payload)
    Logger.info("[DeviceServer #{device.id}] Received data: #{inspect(data)}")

    # 2. Check for threshold violations
    # violations = Ankaa.Monitoring.Thresholds.check(device, data)
    # violations = []

    # 3. If violations, create alerts
    # if !Enum.empty?(violations) do
    #   Alerts.create_alerts_for_violations(patient, violations)
    # end

    # 4. Asynchronously save the reading to the database (the "Scribe")
    # Task.start(fn -> Ankaa.Monitoring.save_reading(data) end)

    # 5. Broadcast to the LiveView UI for real-time updates
    # Phoenix.PubSub.broadcast(Ankaa.PubSub, "topic_for_ui", {:new_reading, data})

    {:noreply, state}
  end

  defp via_tuple(device_id), do: {:via, Registry, {Ankaa.Monitoring.DeviceRegistry, device_id}}
end
