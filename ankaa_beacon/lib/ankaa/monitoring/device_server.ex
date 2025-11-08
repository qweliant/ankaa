defmodule Ankaa.Monitoring.DeviceServer do
  @moduledoc """
  A GenServer that manages telemetry data for a specific medical device.
  It processes incoming readings, checks for threshold violations,
  triggers alerts, broadcasts updates, and persists data.
  """
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
    thresholds = Ankaa.Monitoring.Threshold.get_for_patient(patient)
    {:ok, %{device: device, patient: patient, thresholds: thresholds}}
  end

  @impl true
  def handle_cast({:new_reading, payload}, state) do
    %{device: device, patient: patient, thresholds: custom_thresholds} = state

    # 1. Parse & Structure the incoming data
    data = Jason.decode!(payload)
    # add a `case` statement on `device.type` later.
    reading = Ankaa.Monitoring.BPDeviceReading.from_mqtt(data)

    # 2. Analyze the reading for any threshold violations
    violations = Ankaa.Monitoring.ThresholdChecker.check(reading, custom_thresholds)

    # 3. Trigger alerts if any violations were found
    if !Enum.empty?(violations) do
      Ankaa.Alerts.create_alerts_for_violations(patient, violations)
    end

    # 4. Broadcast the new reading to the patient's LiveView UI
    Phoenix.PubSub.broadcast(
      Ankaa.PubSub,
      pubsub_topic_for(reading),
      {:new_reading, reading, violations}
    )

    # 5. Persist the reading to the database asynchronously
    Task.start(fn -> Ankaa.Monitoring.save_reading(device, reading) end)

    # The GenServer remains ready for the next message
    {:noreply, state}
  end

  defp via_tuple(device_id), do: {:via, Registry, {Ankaa.Monitoring.DeviceRegistry, device_id}}
  defp pubsub_topic_for(%Ankaa.Monitoring.BPDeviceReading{}), do: "bpdevicereading_readings"
  # defp pubsub_topic_for(%DialysisDeviceReading{}), do: "dialysisdevicereading_readings"
end
