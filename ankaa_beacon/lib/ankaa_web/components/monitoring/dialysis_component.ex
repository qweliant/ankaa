defmodule AnkaaWeb.Monitoring.DialysisComponent do
  @moduledoc """
  A LiveComponent for displaying dialysis device readings in real-time.
  It shows the latest readings, highlights any threshold violations,
  and formats timestamps for clarity.
  """
  use AnkaaWeb, :live_component

  defp format_time(datetime) do
    Timex.format!(datetime, "%H:%M:%S", :strftime)
  end
end
