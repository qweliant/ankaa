# defmodule Ankaa.Monitoring.BPReadings do
#   @moduledoc """
#   Context module for handling blood pressure device readings.
#   """
#   import Ecto.Query
#   alias Ankaa.Monitoring.BPDeviceReading
#   alias Ankaa.TimescaleRepo

#   @doc """
#   Creates a blood pressure reading using TimescaleDB's optimized insert.
#   """
#   def create_bp_reading(attrs \\ %{}) do
#     %BPDeviceReading{}
#     |> BPDeviceReading.changeset(attrs)
#     |> TimescaleRepo.insert()
#   end

#   @doc """
#   Creates multiple blood pressure readings in a single transaction using TimescaleDB's optimized bulk insert.
#   """
#   def create_bp_readings(readings) when is_list(readings) do
#     readings
#     |> Enum.map(&BPDeviceReading.changeset(%BPDeviceReading{}, &1))
#     |> TimescaleRepo.insert_all(BPDeviceReading)
#   end

#   @doc """
#   Lists blood pressure readings with optional limit and time range.
#   """
#   def list_bp_readings(opts \\ []) do
#     limit = Keyword.get(opts, :limit, 10)
#     start_time = Keyword.get(opts, :start_time)
#     end_time = Keyword.get(opts, :end_time)

#     query =
#       BPDeviceReading
#       |> order_by([r], desc: r.timestamp)
#       |> limit(^limit)

#     query =
#       if start_time && end_time do
#         query
#         |> where([r], r.timestamp >= ^start_time and r.timestamp <= ^end_time)
#       else
#         query
#       end

#     TimescaleRepo.all(query)
#   end

#   @doc """
#   Gets a single blood pressure reading.
#   """
#   def get_bp_reading!(id), do: TimescaleRepo.get!(BPDeviceReading, id)

#   @doc """
#   Gets blood pressure readings for a specific device with optional time range.
#   """
#   def get_device_readings(device_id, opts \\ []) do
#     limit = Keyword.get(opts, :limit, 10)
#     start_time = Keyword.get(opts, :start_time)
#     end_time = Keyword.get(opts, :end_time)

#     query =
#       BPDeviceReading
#       |> where([r], r.device_id == ^device_id)
#       |> order_by([r], desc: r.timestamp)
#       |> limit(^limit)

#     query =
#       if start_time && end_time do
#         query
#         |> where([r], r.timestamp >= ^start_time and r.timestamp <= ^end_time)
#       else
#         query
#       end

#     TimescaleRepo.all(query)
#   end

#   @doc """
#   Gets aggregated statistics for a device over a time period.
#   """
#   def get_device_statistics(device_id, start_time, end_time) do
#     query = """
#     SELECT
#       time_bucket('1 hour', timestamp) as bucket,
#       AVG(systolic) as avg_systolic,
#       AVG(diastolic) as avg_diastolic,
#       AVG(heart_rate) as avg_heart_rate,
#       COUNT(*) as reading_count,
#       SUM(CASE WHEN risk_level = 'high' THEN 1 ELSE 0 END) as high_risk_count
#     FROM bp_readings
#     WHERE device_id = $1
#       AND timestamp >= $2
#       AND timestamp <= $3
#     GROUP BY bucket
#     ORDER BY bucket DESC
#     """

#     TimescaleRepo.query!(query, [device_id, start_time, end_time])
#   end
# end
