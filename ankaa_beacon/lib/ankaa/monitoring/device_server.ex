defmodule Ankaa.Monitoring.DeviceServer do
  @moduledoc """
  A GenServer that manages telemetry data for a specific medical device.
  It processes incoming readings, checks for threshold violations,
  triggers alerts, broadcasts updates, and persists data.
  """
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
      last_violation_key: last_violation_key,
      violation_start_time: violation_start_time
    } = state

    # Parse & Structure the incoming data
    data = Jason.decode!(payload)

    reading =
      case device.type do
        "blood_pressure" -> Ankaa.Monitoring.BPDeviceReading.from_mqtt(data)
        "dialysis" -> Ankaa.Monitoring.DialysisDeviceReading.from_mqtt(data)
        _ ->
          Logger.warning("Unknown device type: #{device.type}")
          Ankaa.Monitoring.BPDeviceReading.from_mqtt(data)
      end

    # Analyze the reading for any threshold violations
    violations = Ankaa.Monitoring.ThresholdChecker.check(reading, custom_thresholds)

    # Create a unique "signature" for the current set of violations.
    #  For example: `[:high_systolic, :high_heart_rate]` or `[]` if normal.
    current_key = Enum.map(violations, & &1.parameter) |> Enum.sort()

    # Calculate New State & Determine Actions
    # We return a tuple: {new_state, should_alert?}
    {new_state, should_alert?} =
      cond do
        # CASE A: State Changed (New Violation or Back to Normal)
        current_key != last_violation_key ->
          if Enum.any?(violations) do
            # New Violation Started -> Reset Timer, Set Key, Alert = YES
            {%{state | last_violation_key: current_key, violation_start_time: DateTime.utc_now()},
             true}
          else
            # Back to Normal -> Clear Timer, Set Key, Alert = NO
            {%{state | last_violation_key: [], violation_start_time: nil}, false}
          end
        # CASE B: Same State (Persistent Violation) -> Check Nag Timer
        Enum.any?(violations) and should_nudge?(violation_start_time) ->
          # Nag Time Reached -> Reset Timer, Keep Key, Alert = YES
          Logger.info("Re-sending alert for persistent violation")
          {%{state | violation_start_time: DateTime.utc_now()}, true}

        # CASE C: Same State (Normal OR Not yet time to nag)
        true ->
          # No changes needed
          {state, false}
      end

    if should_alert? do
      Logger.info("DeviceServer: Triggering Alert for Patient #{patient.id}")
      Ankaa.Alerts.create_alerts_for_violations(patient, violations)
    end

    Phoenix.PubSub.broadcast(
      Ankaa.PubSub,
      "patient:#{patient.id}:devicereading",
      {:new_reading, reading, violations}
    )

    Task.start(fn -> Ankaa.Monitoring.save_reading(device, reading) end)

    {:noreply, new_state}
  end

  defp via_tuple(device_id), do: {:via, Registry, {Ankaa.Monitoring.DeviceRegistry, device_id}}

  defp should_nudge?(start_time) do
    DateTime.diff(DateTime.utc_now(), start_time, :minute) >= 7
  end
end
