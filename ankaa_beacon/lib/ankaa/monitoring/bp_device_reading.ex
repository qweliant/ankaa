defmodule Ankaa.Monitoring.BPDeviceReading do
  @moduledoc """
  A struct that holds data for a single blood pressure reading.
  """

  # This declares that this module will implement the functions defined in the behaviour.

  defstruct [
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
  ]

  def from_mqtt(data) do
    # This function now returns a plain struct, not an Ecto schema.
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
end
