defmodule Ankaa.Notifications.AlertTimer do
  use GenServer
  require Logger

  @ems_delay :timer.minutes(15)

  def start_link(alert), do: GenServer.start_link(__MODULE__, alert, name: via_tuple(alert.id))
  def cancel(alert_id), do: GenServer.cast(via_tuple(alert_id), :cancel)

  @impl true
  def init(alert) do
    timer_ref = Process.send_after(self(), :call_ems, @ems_delay)
    {:ok, %{alert: alert, timer_ref: timer_ref}}
  end

  @impl true
  def handle_info(:call_ems, state) do
    Logger.critical("EMS TIMER EXPIRED for alert #{state.alert.id}")
    {:stop, :normal, state}
  end

  @impl true
  def handle_cast(:cancel, state) do
    Logger.info("EMS timer cancelled for alert #{state.alert.id}")
    {:stop, :normal, state}
  end

  defp via_tuple(alert_id), do: {:via, Registry, {Notifications.AlertRegistry, alert_id}}
end
