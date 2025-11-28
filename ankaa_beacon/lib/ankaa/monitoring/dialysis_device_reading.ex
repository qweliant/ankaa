defmodule Ankaa.Monitoring.DialysisDeviceReading do
  @moduledoc """
  A struct that holds data for a single dialysis device reading.
  Maps incoming short-code JSON keys (from Rust) to descriptive Elixir atoms.
  """

  defstruct [
    :device_id,
    :timestamp,
    :mode,
    :status,
    :time_in_alarm,
    :time_in_treatment,
    :time_remaining,
    :dialysate_flow_volume,
    :dialysate_flow_rate,
    :ultrafiltration_volume,
    :ultrafiltration_rate,
    :blood_flow_rate,
    :arterial_pressure,
    :venous_pressure,
    :effluent_pressure
  ]

  def from_mqtt(data) do
    %__MODULE__{
      device_id: data["device_id"],
      timestamp: parse_timestamp(data["timestamp"]),
      mode: data["mode"],
      status: data["status"],
      time_in_alarm: data["time_in_alarm"],
      time_in_treatment: data["time_in_treatment"],
      time_remaining: data["time_remaining"],
      dialysate_flow_volume: data["dfv"],
      dialysate_flow_rate: data["dfr"],
      ultrafiltration_volume: data["ufv"],
      ultrafiltration_rate: data["ufr"],
      blood_flow_rate: data["bfr"],
      arterial_pressure: data["ap"],
      venous_pressure: data["vp"],
      effluent_pressure: data["ep"]
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
