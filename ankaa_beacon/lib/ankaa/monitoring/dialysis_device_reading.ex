defmodule Ankaa.Monitoring.DialysisReading do
  @moduledoc """
  Schema and functions for dialysis machine readings
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ankaa.TimescaleRepo
  @behaviour Ankaa.Monitoring.DeviceReading

  @foreign_key_type :binary_id
  schema "dialysis_readings" do
    field(:device_id, :string)
    field(:timestamp, :utc_datetime_usec)
    field(:fluid_level, :integer)
    field(:flow_rate, :integer)
    field(:clot_detected, :boolean)
    field(:patient_id, :binary_id)

    timestamps()
  end

  def changeset(reading, attrs) do
    reading
    |> cast(attrs, [:device_id, :timestamp, :fluid_level, :flow_rate, :clot_detected, :patient_id])
    |> validate_required([:device_id, :timestamp, :fluid_level, :flow_rate])
  end

  @impl true
  def from_mqtt(data) do
    %__MODULE__{
      device_id: data["device_id"],
      timestamp: parse_timestamp(data["timestamp"]),
      fluid_level: data["fluid_level"],
      flow_rate: data["flow_rate"],
      clot_detected: data["clot_detected"]
    }
  end

  defp parse_timestamp(timestamp) when is_binary(timestamp) do
    {:ok, dt, _} = DateTime.from_iso8601(timestamp)
    dt
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
