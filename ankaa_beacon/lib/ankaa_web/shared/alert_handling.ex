defmodule AnkaaWeb.Live.Shared.AlertHandling do
  @moduledoc """
  Provides shared handle_info callbacks for real-time alert events.
  """
  defmacro __using__(_opts) do
    quote do
      alias Ankaa.Alerts

      # Handle new alert broadcasts
      @impl true
      def handle_info({:new_alert, alert}, socket) do
        active_alerts = Alerts.get_active_alerts_for_user(socket.assigns.current_user)
        {:noreply, assign(socket, active_alerts: active_alerts)}
      end

      # Handle alert dismissals
      @impl true
      def handle_info({:alert_dismissed, alert_id}, socket) do
        {:noreply,
         update(socket, :active_alerts, fn items ->
           Enum.reject(items, &(&1.alert.id == alert_id))
         end)}
      end

      # Handle alert updates (like acknowledgments)
      @impl true
      def handle_info({:alert_updated, updated_alert}, socket) do
        updated_alerts =
          Enum.map(socket.assigns.active_alerts, fn item ->
            if item.alert.id == updated_alert.id do
              %{item | alert: updated_alert}
            else
              item
            end
          end)

        {:noreply, assign(socket, active_alerts: updated_alerts)}
      end

      # Handle EMS escalations
      @impl true
      def handle_info({:ems_escalation, alert_id}, socket) do
        {:noreply,
         update(socket, :active_alerts, fn items ->
           Enum.map(items, fn item ->
             if item.alert.id == alert_id do
               updated_nested_alert = %{
                 item.alert
                 | ems_contacted: true,
                   ems_contact_time: DateTime.utc_now()
               }
               %{item | alert: updated_nested_alert}
             else
               item
             end
           end)
         end)}
      end
    end
  end
end
