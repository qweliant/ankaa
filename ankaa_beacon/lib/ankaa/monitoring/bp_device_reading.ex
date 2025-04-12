defmodule Ankaa.Monitoring.BPReading do
  @moduledoc """
  Schema and functions for blood pressure readings
  """
  use Ecto.Schema
  import Ecto.Changeset
  @behaviour Ankaa.Monitoring.DeviceReading

  schema "bp_readings" do
    field(:device_id, :string)
    field(:timestamp, :utc_datetime)
    field(:systolic, :float)
    field(:diastolic, :float)
    field(:heart_rate, :integer)
    field(:risk_level, :string)

    belongs_to(:patient, Ankaa.Accounts.User)

    timestamps()
  end

  @impl true
  def from_mqtt(data) do
    # Convert MQTT JSON payload to struct
    %__MODULE__{
      device_id: data["device_id"],
      timestamp: DateTime.from_iso8601(data["timestamp"]) |> elem(1),
      systolic: data["systolic"],
      diastolic: data["diastolic"],
      heart_rate: data["heart_rate"],
      risk_level: data["risk_level"]
    }
  end

  @impl true
  def check_thresholds(reading) do
    # Logic to check if reading exceeds thresholds
    violations = []

    # Check systolic pressure
    cond do
      reading.systolic > 180 ->
        violations = [
          %Ankaa.Monitoring.ThresholdViolation{
            parameter: :systolic,
            value: reading.systolic,
            threshold: 180,
            severity: :critical,
            message: "Systolic pressure dangerously high"
          }
          | violations
        ]

      reading.systolic > 140 ->
        violations = [
          %Ankaa.Monitoring.ThresholdViolation{
            parameter: :systolic,
            value: reading.systolic,
            threshold: 140,
            severity: :high,
            message: "Systolic pressure high"
          }
          | violations
        ]

      reading.systolic < 70 ->
        violations = [
          %Ankaa.Monitoring.ThresholdViolation{
            parameter: :systolic,
            value: reading.systolic,
            threshold: 70,
            severity: :critical,
            message: "Systolic pressure dangerously low"
          }
          | violations
        ]

      reading.systolic < 90 ->
        violations = [
          %Ankaa.Monitoring.ThresholdViolation{
            parameter: :systolic,
            value: reading.systolic,
            threshold: 90,
            severity: :high,
            message: "Systolic pressure low"
          }
          | violations
        ]

      true ->
        violations
    end

    # Similar logic for diastolic and heart_rate

    # Check risk level from device
    if reading.risk_level == "high" do
      violations = [
        %Ankaa.Monitoring.ThresholdViolation{
          parameter: :risk_level,
          value: reading.risk_level,
          threshold: "medium",
          severity: :high,
          message: "High risk level detected"
        }
        | violations
      ]
    end

    violations
  end
end
