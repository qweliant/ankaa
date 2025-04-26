defmodule Ankaa.Monitoring.BPDeviceReading do
  @moduledoc """
  Schema for blood pressure device readings stored in TimescaleDB.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ankaa.Monitoring.ThresholdViolation
  @behaviour Ankaa.Monitoring.DeviceReading

  @primary_key false
  schema "blood_pressure_device_readings" do
    field(:device_id, :string)
    field(:timestamp, :utc_datetime)

    # Mode and Status
    field(:mode, :string)
    field(:status, :string)

    # Blood pressure metrics
    field(:systolic, :integer)
    field(:diastolic, :integer)
    field(:heart_rate, :integer)
    field(:mean_arterial_pressure, :integer)
    field(:pulse_pressure, :integer)
    field(:irregular_heartbeat, :boolean)

    timestamps()
  end

  @doc false
  def changeset(reading, attrs) do
    reading
    |> cast(attrs, [
      :device_id,
      :timestamp,
      :mode,
      :status,
      :systolic,
      :diastolic,
      :heart_rate,
      :mean_arterial_pressure,
      :pulse_pressure,
      :irregular_heartbeat
    ])
    |> validate_required([
      :device_id,
      :timestamp,
      :mode,
      :status,
      :systolic,
      :diastolic,
      :heart_rate,
      :mean_arterial_pressure,
      :pulse_pressure,
      :irregular_heartbeat
    ])
    |> validate_number(:systolic, greater_than: 0)
    |> validate_number(:diastolic, greater_than: 0)
    |> validate_number(:heart_rate, greater_than: 0)
    |> validate_number(:mean_arterial_pressure, greater_than: 0)
    |> validate_number(:pulse_pressure, greater_than: 0)
  end

  @impl true
  def from_mqtt(data) do
    %__MODULE__{
      device_id: data["device_id"],
      timestamp: parse_timestamp(data["timestamp"]),
      mode: data["mode"],
      status: data["status"],
      systolic: data["systolic"],
      diastolic: data["diastolic"],
      heart_rate: data["heart_rate"],
      mean_arterial_pressure: data["mean_arterial_pressure"],
      pulse_pressure: data["pulse_pressure"],
      irregular_heartbeat: data["irregular_heartbeat"]
    }
  end

  defp parse_timestamp(nil), do: DateTime.utc_now()

  defp parse_timestamp(%DateTime{} = dt), do: dt

  defp parse_timestamp(timestamp) when is_binary(timestamp) do
    case DateTime.from_iso8601(timestamp) do
      {:ok, dt, _} -> dt
      _ -> DateTime.utc_now()
    end
  end

  @impl true
  def check_thresholds(reading) do
    violations = []

    # Status-based alerts
    violations =
      case reading.status do
        "critical" ->
          [
            %ThresholdViolation{
              parameter: :status,
              value: reading.status,
              threshold: "normal",
              severity: :critical,
              message: "🚨 Critical blood pressure"
            }
            | violations
          ]

        "warning" ->
          [
            %ThresholdViolation{
              parameter: :status,
              value: reading.status,
              threshold: "normal",
              severity: :high,
              message: "⚠️ Blood pressure caution"
            }
            | violations
          ]

        _ ->
          violations
      end

    # Systolic pressure alerts
    violations =
      if reading.systolic > 180 do
        [
          %ThresholdViolation{
            parameter: :systolic,
            value: reading.systolic,
            threshold: 180,
            severity: :critical,
            message: "🩸 High systolic pressure (#{reading.systolic} mmHg)"
          }
          | violations
        ]
      else
        violations
      end

    # Diastolic pressure alerts
    violations =
      if reading.diastolic > 120 do
        [
          %ThresholdViolation{
            parameter: :diastolic,
            value: reading.diastolic,
            threshold: 120,
            severity: :critical,
            message: "🩸 High diastolic pressure (#{reading.diastolic} mmHg)"
          }
          | violations
        ]
      else
        violations
      end

    # Heart rate alerts
    violations =
      if reading.heart_rate > 100 do
        [
          %ThresholdViolation{
            parameter: :heart_rate,
            value: reading.heart_rate,
            threshold: 100,
            severity: :high,
            message: "💓 High heart rate (#{reading.heart_rate} bpm)"
          }
          | violations
        ]
      else
        violations
      end

    # Irregular heartbeat alerts
    violations =
      if reading.irregular_heartbeat do
        [
          %ThresholdViolation{
            parameter: :irregular_heartbeat,
            value: true,
            threshold: false,
            severity: :high,
            message: "💔 Irregular heartbeat detected"
          }
          | violations
        ]
      else
        violations
      end

    violations
  end
end
