defmodule AnkaaWeb.Monitoring.BPComponent do
  use AnkaaWeb, :live_component

  # We'll move the time formatting helper here since it's used by the template.
  defp format_time(datetime) do
    Timex.format!(datetime, "%H:%M:%S", :strftime)
  end
end
