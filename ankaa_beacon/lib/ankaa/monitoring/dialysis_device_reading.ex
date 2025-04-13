defmodule Ankaa.Monitoring.DialysisReading do
  @moduledoc """
  Schema for dialysis device readings with comprehensive monitoring fields.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ankaa.TimescaleRepo
  @behaviour Ankaa.Monitoring.DeviceReading

  @foreign_key_type :binary_id
  schema "dialysis_readings" do
    field(:device_id, :string)
    field(:timestamp, :utc_datetime_usec)

    field(:mode, Ecto.Enum,
      values: [:standby, :prime, :connect, :treatment, :disconnect, :rinseback]
    )

    field(:status, Ecto.Enum, values: [:green, :yellow, :red])
    # seconds
    field(:time_in_alarm, :integer)
    # seconds
    field(:time_in_treatment, :integer)
    # seconds
    field(:time_remaining, :integer)
    # Dialysate Fluid Volume (L)
    field(:dfv, :float)
    # Dialysate Flow Rate (L/hr)
    field(:dfr, :float)
    # Ultrafiltration Volume (L)
    field(:ufv, :float)
    # Ultrafiltration Rate (L/hr)
    field(:ufr, :float)
    # Blood Flow Rate (ml/min)
    field(:bfr, :integer)
    # Arterial Pressure (mmHg)
    field(:ap, :integer)
    # Venous Pressure (mmHg)
    field(:vp, :integer)
    # Effluent Pressure (mmHg)
    field(:ep, :integer)
    field(:patient_id, Ecto.UUID)

    timestamps(type: :utc_datetime_usec)
  end

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
      :ep,
      :patient_id
    ])
    |> validate_required([
      :device_id,
      :timestamp,
      :mode,
      :status,
      :patient_id
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
      ep: data["ep"],
      patient_id: data["patient_id"]
    }
  end

  defp parse_timestamp(timestamp) when is_binary(timestamp) do
    {:ok, dt, _} = DateTime.from_iso8601(timestamp)
    dt
  end

  @impl true
  def check_thresholds(reading) do
    violations = []

    # Status-based alerts
    violations =
      case reading.status do
        :red -> ["🔴 Critical system alarm"] ++ violations
        :yellow -> ["⚠️ System caution"] ++ violations
        _ -> violations
      end

    # Time-based alerts
    violations =
      if reading.time_in_alarm > 30 do
        ["⏱ Alarm active for more than 30 seconds"] ++ violations
      else
        violations
      end

    # Blood flow alerts
    violations =
      if reading.bfr < 200 do
        ["🚨 Low blood flow rate (#{reading.bfr} ml/min)"] ++ violations
      else
        violations
      end

    # Pressure alerts
    violations =
      if reading.vp > 300 do
        ["🧠 High venous pressure (#{reading.vp} mmHg)"] ++ violations
      else
        violations
      end

    # Flow rate alerts
    violations =
      if reading.dfr < 300 do
        ["📉 Low dialysate flow rate (#{reading.dfr} L/hr)"] ++ violations
      else
        violations
      end

    # Treatment status alerts
    violations =
      if reading.mode == :disconnect && reading.time_remaining > 0 do
        ["⚠️ Treatment ended prematurely"] ++ violations
      else
        violations
      end

    violations
  end
end
