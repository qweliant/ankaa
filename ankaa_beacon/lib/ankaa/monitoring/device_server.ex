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

    {:ok,
     %{
       device: device,
       patient: patient,
       thresholds: thresholds,
       last_violation_key: []
     }}
  end

  @impl true
  def handle_cast({:new_reading, payload}, state) do
    %{
      device: device,
      patient: patient,
      thresholds: custom_thresholds,
      last_violation_key: last_key
    } = state

    # 1. Parse & Structure the incoming data
    data = Jason.decode!(payload)
    reading = Ankaa.Monitoring.BPDeviceReading.from_mqtt(data)

    # 2. Analyze the reading for any threshold violations
    violations = Ankaa.Monitoring.ThresholdChecker.check(reading, custom_thresholds)

    # 3. Create a unique "signature" for the current set of violations.
    #    For example: `[:high_systolic, :high_heart_rate]` or `[]` if normal.
    current_key = Enum.map(violations, & &1.parameter) |> Enum.sort()

    # 4. Trigger alerts ONLY if the state has changed.
    if current_key != last_key do
      # The patient's condition has changed.
      # Only create alerts if the new state is actually a violation.
      if Enum.any?(violations) do
        Logger.info(
          "[DeviceServer #{device.id}] New violation detected (was: #{inspect(last_key)}, is: #{inspect(current_key)}). Sending alert."
        )
        Ankaa.Alerts.create_alerts_for_violations(patient, violations)
      else
        Logger.info(
          "[DeviceServer #{device.id}] Violation state cleared (was: #{inspect(last_key)}, is: normal)."
        )
      end
    end

    # 5. Broadcast the new reading to the patient's LiveView UI
    Phoenix.PubSub.broadcast(
      Ankaa.PubSub,
      pubsub_topic_for(reading),
      {:new_reading, reading, violations}
    )

    # 6. Persist the reading to the database asynchronously
    Task.start(fn -> Ankaa.Monitoring.save_reading(device, reading) end)

    # 7. Update the state for the next check
    new_state = %{state | last_violation_key: current_key}
    {:noreply, new_state}
  end

  defp via_tuple(device_id), do: {:via, Registry, {Ankaa.Monitoring.DeviceRegistry, device_id}}
  defp pubsub_topic_for(%Ankaa.Monitoring.BPDeviceReading{}), do: "bpdevicereading_readings"
  # defp pubsub_topic_for(%DialysisDeviceReading{}), do: "dialysisdevicereading_readings"
end
