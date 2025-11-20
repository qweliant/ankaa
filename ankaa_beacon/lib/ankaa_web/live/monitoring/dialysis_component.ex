defmodule AnkaaWeb.Monitoring.DialysisComponent do
  use AnkaaWeb, :live_component

  defp format_time(datetime) do
    Timex.format!(datetime, "%H:%M:%S", :strftime)
  end
end
