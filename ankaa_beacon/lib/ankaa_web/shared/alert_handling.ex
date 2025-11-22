defmodule AnkaaWeb.Live.Shared.AlertHandling do
  @moduledoc """
  Provides shared handle_info callbacks for real-time alert events.
  """
  defmacro __using__(_opts) do
    quote do
      alias Ankaa.Alerts
      alias Ankaa.Messages
      require Logger

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

      @impl true
      def handle_info({:new_message, message}, socket) do
        current_user = socket.assigns.current_user

        socket =
          cond do
            !is_nil(current_user.patient) and
                String.contains?(message.content, "checking in") ->
              assign(socket, :toast_message, message)

            is_nil(current_user.patient) and
                String.contains?(message.content, "I'm OK!") ->
              assign(socket, :toast_message, message)

            true ->
              socket
          end

        {:noreply, socket}
      end

      @impl true
      def handle_event("send_check_in_reply", %{"message_id" => message_id}, socket) do
        patient = socket.assigns.current_user.patient
        original_message = socket.assigns.toast_message

        if original_message && original_message.id == message_id do
          Messages.send_check_in_reply(patient, original_message)
        end

        {:noreply, assign(socket, :toast_message, nil)}
      end

      @impl true
      def handle_event("dismiss_toast", _, socket) do
        {:noreply, assign(socket, :toast_message, nil)}
      end
    end
  end
end
