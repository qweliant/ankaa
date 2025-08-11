# defmodule Ankaa.Monitoring.DialysisReadings do
#   @moduledoc """
#   Context module for handling dialysis device readings.
#   """
#   import Ecto.Query
#   alias Ankaa.Monitoring.DialysisDeviceReading
#   alias Ankaa.TimescaleRepo

#   @doc """
#   Creates a dialysis reading using TimescaleDB's optimized insert.
#   """
#   def create_dialysis_reading(attrs \\ %{}) do
#     %DialysisDeviceReading{}
#     |> DialysisDeviceReading.changeset(attrs)
#     |> TimescaleRepo.insert()
#   end

#   @doc """
#   Creates multiple dialysis readings in a single transaction using TimescaleDB's optimized bulk insert.
#   """
#   def create_dialysis_readings(readings) when is_list(readings) do
#     readings
#     |> Enum.map(&DialysisDeviceReading.changeset(%DialysisDeviceReading{}, &1))
#     |> TimescaleRepo.insert_all(DialysisDeviceReading)
#   end

#   @doc """
#   Lists dialysis readings with optional limit and time range.
#   """
#   def list_dialysis_readings(opts \\ []) do
#     limit = Keyword.get(opts, :limit, 10)
#     start_time = Keyword.get(opts, :start_time)
#     end_time = Keyword.get(opts, :end_time)

#     query =
#       DialysisDeviceReading
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
#   Gets a single dialysis reading.
#   """
#   def get_dialysis_reading!(id), do: TimescaleRepo.get!(DialysisDeviceReading, id)

#   @doc """
#   Gets dialysis readings for a specific device with optional time range.
#   """
#   def get_device_readings(device_id, opts \\ []) do
#     limit = Keyword.get(opts, :limit, 10)
#     start_time = Keyword.get(opts, :start_time)
#     end_time = Keyword.get(opts, :end_time)

#     query =
#       DialysisDeviceReading
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
#       AVG(fluid_level) as avg_fluid_level,
#       AVG(flow_rate) as avg_flow_rate,
#       COUNT(*) as reading_count,
#       SUM(CASE WHEN clot_detected THEN 1 ELSE 0 END) as clot_count
#     FROM dialysis_device_readings
#     WHERE device_id = $1
#       AND timestamp >= $2
#       AND timestamp <= $3
#     GROUP BY bucket
#     ORDER BY bucket DESC
#     """

#     TimescaleRepo.query!(query, [device_id, start_time, end_time])
#   end
# end
