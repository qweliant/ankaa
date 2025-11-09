defmodule Ankaa.Notifications.EMSAlertTimer do
  @moduledoc """
  A timer that triggers an emergency medical services (EMS) alert
  if not cancelled within a specified duration.
  """
  use GenServer
  require Logger

  @ems_delay :timer.minutes(15)

  # start link is called on ln 50 or so in the alerts context and again
  # im not sure why. maybe these start and stop the servers. but if it starts a server
  # how does ems actually get called?
  def start_link(alert), do: GenServer.start_link(__MODULE__, alert, name: via_tuple(alert.id))
  def cancel(alert_id), do: GenServer.cast(via_tuple(alert_id), :cancel) # not sure why i have to call handle cast

  @impl true
  def init(alert) do
    timer_ref = Process.send_after(self(), :call_ems, @ems_delay)
    {:ok, %{alert: alert, timer_ref: timer_ref}}
  end

  @impl true
  def handle_info(:call_ems, state) do
    Logger.critical("EMS timer is triggering a call for alert #{state.alert.id}")
    {:stop, :normal, state}
  end

  @impl true
  def handle_cast(:cancel, state) do
    Logger.info("EMS timer cancelled for alert #{state.alert.id}")
    {:stop, :normal, state}
  end

  defp via_tuple(alert_id), do: {:via, Registry, {Ankaa.Notifications.AlertRegistry, alert_id}}
end
