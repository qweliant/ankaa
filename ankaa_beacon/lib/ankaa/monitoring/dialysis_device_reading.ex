defmodule Ankaa.Monitoring.DialysisReading do
  @moduledoc """
  Schema and functions for dialysis machine readings
  """
  use Ecto.Schema
  import Ecto.Changeset
  @behaviour Ankaa.Monitoring.DeviceReading

  schema "dialysis_readings" do
    field(:device_id, :string)
    field(:timestamp, :utc_datetime)
    field(:fluid_level, :integer)
    field(:flow_rate, :integer)
    field(:clot_detected, :boolean)

    belongs_to(:patient, Ankaa.Accounts.User)

    timestamps()
  end

  @impl true
  def from_mqtt(data) do
    # Convert MQTT JSON payload to struct
    %__MODULE__{
      device_id: data["device_id"],
      timestamp: DateTime.from_iso8601(data["timestamp"]) |> elem(1),
      fluid_level: data["fluid_level"],
      flow_rate: data["flow_rate"],
      clot_detected: data["clot_detected"]
    }
  end

  @impl true
  def check_thresholds(reading) do
    # Logic to check if reading exceeds thresholds
    violations = []

    # Check for clot detection - critical alert
    if reading.clot_detected do
      violations = [
        %Ankaa.Monitoring.ThresholdViolation{
          parameter: :clot_detected,
          value: true,
          threshold: false,
          severity: :critical,
          message: "Blood clot detected"
        }
        | violations
      ]
    end

    # Check fluid levels - use cond instead of if/elseif
    cond do
      reading.fluid_level < 100 ->
        violations = [
          %Ankaa.Monitoring.ThresholdViolation{
            parameter: :fluid_level,
            value: reading.fluid_level,
            threshold: 100,
            severity: :high,
            message: "Fluid level critically low"
          }
          | violations
        ]

      reading.fluid_level < 300 ->
        violations = [
          %Ankaa.Monitoring.ThresholdViolation{
            parameter: :fluid_level,
            value: reading.fluid_level,
            threshold: 300,
            severity: :medium,
            message: "Fluid level low"
          }
          | violations
        ]

      true ->
        # Default case, no violation
        violations
    end

    # Check flow rate
    # Add similar logic for flow_rate

    violations
  end
end
