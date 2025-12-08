defmodule Ankaa.Monitoring.DeviceServer do
  @moduledoc """
  A GenServer that manages telemetry data for a specific medical device.
  It processes incoming readings, checks for threshold violations,
  triggers alerts, broadcasts updates, and persists data.
  """
  alias ElixirSense.Log
  use GenServer, restart: :transient
  require Logger

  def start_link(%Ankaa.Patients.Device{} = device) do
    GenServer.start_link(__MODULE__, device, name: via_tuple(device.id))
  end

  def handle_reading(pid, payload) when is_pid(pid) do
    GenServer.cast(pid, {:new_reading, payload})
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
       last_violation_key: [],
       violation_start_time: nil
     }}
  end

  @impl true
  def handle_cast({:new_reading, payload}, state) do
    %{
      device: device,
      patient: patient,
      thresholds: custom_thresholds,
      last_violation_key: last_violation_key
    } = state

    # 1. Parse & Structure the incoming data
    data = Jason.decode!(payload)

    reading =
      case device.type do
        "blood_pressure" ->
          Ankaa.Monitoring.BPDeviceReading.from_mqtt(data)

        "dialysis" ->
          Ankaa.Monitoring.DialysisDeviceReading.from_mqtt(data)

        _ ->
          Logger.warning("Unknown device type: #{device.type}")
          # Fallback
          Ankaa.Monitoring.BPDeviceReading.from_mqtt(data)
      end
    Logger.info("Received new reading: #{inspect(reading)}")
    # 2. Analyze the reading for any threshold violations
    violations = Ankaa.Monitoring.ThresholdChecker.check(reading, custom_thresholds)

    # 3. Create a unique "signature" for the current set of violations.
    #    For example: `[:high_systolic, :high_heart_rate]` or `[]` if normal.
    current_key = Enum.map(violations, & &1.parameter) |> Enum.sort()

    # 4. Compare with the last known violation state
    if current_key != last_violation_key do
      # staete has changed
      if Enum.any?(violations) do
        # New Violation: Send Alert & Start Timer
        Ankaa.Alerts.create_alerts_for_violations(patient, violations)

        {:noreply,
         %{state | last_violation_key: current_key, violation_start_time: DateTime.utc_now()}}
      else
        # Cleared: Reset Timer
        {:noreply, %{state | last_violation_key: [], violation_start_time: nil}}
      end
    else
      # SAME STATE (High -> High)
      # Check if we need to "Nag" (e.g., every 15 mins)
      if state.violation_start_time && should_nudge?(state.violation_start_time) do
        Logger.info("Re-sending alert for persistent violation")
        Ankaa.Alerts.create_alerts_for_violations(patient, violations)
        # Reset timer to nag again later
        {:noreply, %{state | violation_start_time: DateTime.utc_now()}}
      else
        {:noreply, state}
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

  defp pubsub_topic_for(%Ankaa.Monitoring.DialysisDeviceReading{}),
    do: "dialysisdevicereading_readings"

  defp should_nudge?(start_time) do
    DateTime.diff(DateTime.utc_now(), start_time, :minute) >= 7
  end
end
