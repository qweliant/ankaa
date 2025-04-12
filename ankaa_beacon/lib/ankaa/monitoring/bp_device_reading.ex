defmodule Ankaa.Monitoring.BPReading do
  @moduledoc """
  Schema and functions for blood pressure readings
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ankaa.TimescaleRepo
  @behaviour Ankaa.Monitoring.DeviceReading

  @foreign_key_type :binary_id
  schema "bp_readings" do
    field(:device_id, :string)
    field(:timestamp, :utc_datetime_usec)
    field(:systolic, :float)
    field(:diastolic, :float)
    field(:heart_rate, :integer)
    field(:risk_level, :string)
    field(:patient_id, :binary_id)

    timestamps()
  end

  def changeset(reading, attrs) do
    reading
    |> cast(attrs, [
      :device_id,
      :timestamp,
      :systolic,
      :diastolic,
      :heart_rate,
      :risk_level,
      :patient_id
    ])
    |> validate_required([:device_id, :timestamp, :systolic, :diastolic, :heart_rate])
    |> validate_inclusion(:risk_level, ["low", "medium", "high"])
  end

  @impl true
  def from_mqtt(data) do
    %__MODULE__{
      device_id: data["device_id"],
      timestamp: parse_timestamp(data["timestamp"]),
      systolic: data["systolic"],
      diastolic: data["diastolic"],
      heart_rate: data["heart_rate"],
      risk_level: data["risk_level"]
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
