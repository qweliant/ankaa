defmodule Ankaa.Monitoring.DialysisDeviceReading do
  @moduledoc """
  Schema for dialysis device readings stored in TimescaleDB.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ankaa.Monitoring.ThresholdViolation
  @behaviour Ankaa.Monitoring.DeviceReading

  @primary_key false
  schema "dialysis_device_readings" do
    field(:device_id, :string)
    field(:timestamp, :utc_datetime)

    # Mode and Status
    field(:mode, :string)
    field(:status, :string)

    # Time-based metrics
    field(:time_in_alarm, :integer)
    field(:time_in_treatment, :integer)
    field(:time_remaining, :integer)

    # Fluid metrics
    # Dialysate Fluid Volume (L)
    field(:dfv, :float)
    # Dialysate Flow Rate (L/hr)
    field(:dfr, :float)
    # Ultrafiltration Volume (L)
    field(:ufv, :float)
    # Ultrafiltration Rate (L/hr)
    field(:ufr, :float)

    # Blood flow and pressure metrics
    # Blood Flow Rate (ml/min)
    field(:bfr, :integer)
    # Arterial Pressure (mmHg)
    field(:ap, :integer)
    # Venous Pressure (mmHg)
    field(:vp, :integer)
    # Effluent Pressure (mmHg)
    field(:ep, :integer)

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
      :time_in_alarm,
      :time_in_treatment,
      :time_remaining,
      :dfv,
      :dfr,
      :ufv,
      :ufr,
      :bfr,
      :ap,
      :vp,
      :ep
    ])
    |> validate_required([
      :device_id,
      :timestamp,
      :mode,
      :status,
      :time_in_treatment,
      :time_remaining,
      :dfv,
      :dfr,
      :ufv,
      :ufr,
      :bfr,
      :ap,
      :vp,
      :ep
    ])
    |> validate_number(:dfv, greater_than_or_equal_to: 0)
    |> validate_number(:dfr, greater_than_or_equal_to: 0)
    |> validate_number(:ufv, greater_than_or_equal_to: 0)
    |> validate_number(:ufr, greater_than_or_equal_to: 0)
    |> validate_number(:bfr, greater_than_or_equal_to: 0)
  end

  @impl true
  def from_mqtt(data) do
    %__MODULE__{
      device_id: data["device_id"],
      timestamp: parse_timestamp(data["timestamp"]),
      mode: data["mode"],
      status: data["status"],
      time_in_alarm: data["time_in_alarm"],
      time_in_treatment: data["time_in_treatment"],
      time_remaining: data["time_remaining"],
      dfv: data["dfv"],
      dfr: data["dfr"],
      ufv: data["ufv"],
      ufr: data["ufr"],
      bfr: data["bfr"],
      ap: data["ap"],
      vp: data["vp"],
      ep: data["ep"]
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
              message: "🚨 Critical system alarm"
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
              message: "⚠️ System caution"
            }
            | violations
          ]

        _ ->
          violations
      end

    # Time-based alerts
    violations =
      if reading.time_in_alarm && reading.time_in_alarm > 30 do
        [
          %ThresholdViolation{
            parameter: :time_in_alarm,
            value: reading.time_in_alarm,
            threshold: 30,
            severity: :high,
            message: "⏰ Alarm active for more than 30 seconds"
          }
          | violations
        ]
      else
        violations
      end

    # Blood flow alerts
    violations =
      if reading.bfr < 200 do
        [
          %ThresholdViolation{
            parameter: :bfr,
            value: reading.bfr,
            threshold: 200,
            severity: :critical,
            message: "🩸 Low blood flow rate (#{reading.bfr} ml/min)"
          }
          | violations
        ]
      else
        violations
      end

    # Pressure alerts
    violations =
      if reading.vp > 300 do
        [
          %ThresholdViolation{
            parameter: :vp,
            value: reading.vp,
            threshold: 300,
            severity: :critical,
            message: "💢 High venous pressure (#{reading.vp} mmHg)"
          }
          | violations
        ]
      else
        violations
      end

    # Flow rate alerts
    violations =
      if reading.dfr < 300 do
        [
          %ThresholdViolation{
            parameter: :dfr,
            value: reading.dfr,
            threshold: 300,
            severity: :high,
            message: "💧 Low dialysate flow rate (#{reading.dfr} L/hr)"
          }
          | violations
        ]
      else
        violations
      end

    # Treatment status alerts
    violations =
      if reading.mode == "disconnect" && reading.time_remaining > 0 do
        [
          %ThresholdViolation{
            parameter: :mode,
            value: reading.mode,
            threshold: "treatment",
            severity: :critical,
            message: "❌ Treatment ended prematurely"
          }
          | violations
        ]
      else
        violations
      end

    violations
  end
end
