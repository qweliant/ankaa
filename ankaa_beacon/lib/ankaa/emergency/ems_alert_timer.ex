defmodule Ankaa.Emergency.EMSAlertTimer do
  @moduledoc """
  A timer that triggers an emergency medical services (EMS) alert
  if not cancelled within a specified duration.
  """
  use GenServer
  require Logger

  @ems_delay :timer.minutes(7)

  def start_link(alert), do: GenServer.start_link(__MODULE__, alert, name: via_tuple(alert.id))
  def cancel(alert_id), do: GenServer.cast(via_tuple(alert_id), :cancel)

  @impl true
  def init(alert) do
    timer_ref = Process.send_after(self(), :call_ems, @ems_delay)
    Logger.info("EMS timer started for alert #{alert.id}, will trigger in #{@ems_delay} ms")
    {:ok, %{alert: alert, timer_ref: timer_ref}}
  end

  @impl true
  def handle_info(:call_ems, state) do
    alert =
      Ankaa.Repo.get!(Ankaa.Notifications.Alert, state.alert.id) |> Ankaa.Repo.preload(:patient)

    Logger.critical("⏳ EMS Timer Expired for Alert #{alert.id}. Triggering Dispatch.")

    case Ankaa.Emergency.trigger_ems(alert.patient, alert) do
      {:ok, dispatch_id} ->
        Logger.info("EMS Dispatch ID received: #{dispatch_id}")

      # Update Alert status to indicate EMS was called?
      # Ankaa.Alerts.update_alert_status(alert, "ems_called")

      {:error, reason} ->
        Logger.error("Failed to trigger EMS: #{inspect(reason)}")
    end

    {:stop, :normal, state}
  end

  @impl true
  def handle_cast(:cancel, state) do
    Logger.info("EMS timer cancelled for alert #{state.alert.id}")
    Process.cancel_timer(state.timer_ref)
    {:stop, :normal, state}
  end

  defp via_tuple(alert_id), do: {:via, Registry, {Ankaa.Notifications.AlertRegistry, alert_id}}
end
