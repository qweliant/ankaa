defmodule AnkaaWeb.Live.Shared.AlertHandling do
  @moduledoc """
  Provides shared handle_info callbacks for real-time alert events.
  """
  defmacro __using__(_opts) do
    quote do
      # Handle new alert broadcasts
      @impl true
      def handle_info({:new_alert, alert}, socket) do
        {:noreply, update(socket, :active_alerts, fn alerts -> [alert | alerts] end)}
      end

      # Handle alert dismissals
      @impl true
      def handle_info({:alert_dismissed, alert_id}, socket) do
        {:noreply,
         update(socket, :active_alerts, fn alerts ->
           Enum.reject(alerts, &(&1.id == alert_id))
         end)}
      end

      # Handle alert updates (like acknowledgments)
      @impl true
      def handle_info({:alert_updated, updated_alert}, socket) do
        updated_alerts =
          Enum.map(socket.assigns.active_alerts, fn alert ->
            if alert.id == updated_alert.id, do: updated_alert, else: alert
          end)

        {:noreply, assign(socket, active_alerts: updated_alerts)}
      end

      # Handle EMS escalations
      @impl true
      def handle_info({:ems_escalation, alert_id}, socket) do
        {:noreply,
         update(socket, :active_alerts, fn alerts ->
           Enum.map(alerts, fn alert ->
             if alert.id == alert_id do
               %{alert | ems_contacted: true, ems_contact_time: DateTime.utc_now()}
             else
               alert
             end
           end)
         end)}
      end
    end
  end
end
