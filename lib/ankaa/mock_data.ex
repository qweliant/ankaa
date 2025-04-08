defmodule AnkaaBeacon.MockData do
  use GenServer
  alias AnkaaBeacon.Redis

  @moduledoc """
  A GenServer that simulates real-time BP and dialysis machine data with enhanced realism.
  """

  # Configuration for data generation
  @patients [
    %{
      id: "12345",
      name: "John Doe",
      age: 65,
      baseline_systolic: 130,
      baseline_diastolic: 80,
      chronic_conditions: [:hypertension, :diabetes]
    },
    %{
      id: "67890",
      name: "Jane Smith",
      age: 57,
      baseline_systolic: 125,
      baseline_diastolic: 75,
      chronic_conditions: []
    }
  ]

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    schedule_next_reading()
    {:ok, state}
  end

  def handle_info(:generate_data, state) do
    Enum.each(@patients, fn patient ->
      generate_bp_reading(patient)
      generate_dialysis_reading(patient)
    end)

    schedule_next_reading()
    {:noreply, state}
  end

  defp generate_bp_reading(patient) do
    # More realistic BP simulation considering patient's baseline and conditions
    systolic_variation =
      case :hypertension in patient.chronic_conditions do
        true -> Enum.random(-20..20)
        false -> Enum.random(-10..10)
      end

    diastolic_variation =
      case :hypertension in patient.chronic_conditions do
        true -> Enum.random(-15..15)
        false -> Enum.random(-8..8)
      end

    bp_data = %{
      patient_id: patient.id,
      patient_name: patient.name,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      systolic: max(90, min(180, patient.baseline_systolic + systolic_variation)),
      diastolic: max(60, min(120, patient.baseline_diastolic + diastolic_variation)),
      heart_rate: Enum.random(60..100),
      risk_level: calculate_bp_risk(patient)
    }

    Redis.publish("bp_readings", Jason.encode!(bp_data))
  end

  defp generate_dialysis_reading(patient) do
    dialysis_data = %{
      patient_id: patient.id,
      patient_name: patient.name,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      fluid_level: Enum.random(400..600),
      flow_rate: Enum.random(200..350),
      clot_risk: calculate_clot_risk(patient),
      clot_detected: Enum.random([true, false])
    }

    Redis.publish("dialysis_readings", Jason.encode!(dialysis_data))
  end

  defp calculate_bp_risk(patient) do
    conditions = patient.chronic_conditions

    base_risk =
      cond do
        :hypertension in conditions and :diabetes in conditions -> "high"
        :hypertension in conditions -> "moderate"
        :diabetes in conditions -> "moderate"
        true -> "low"
      end

    base_risk
  end

  defp calculate_clot_risk(patient) do
    # Simplified clot risk calculation
    base_risk =
      case patient.age do
        age when age > 60 -> "high"
        age when age > 45 -> "moderate"
        _ -> "low"
      end

    base_risk
  end

  defp schedule_next_reading do
    # Randomize interval slightly for more natural simulation
    interval = Enum.random(1_500..2_500)
    Process.send_after(self(), :generate_data, interval)
  end
end
