defmodule AnkaaWeb.AlertBanner do
  @moduledoc """
  A LiveComponent that displays active alerts to users.
  """

  use AnkaaWeb, :live_component

  alias Ankaa.Alerts
  alias Ankaa.Notifications
  alias Ankaa.Accounts

  require Logger

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("dismiss_alert", %{"alert_id" => alert_id}, socket) do
    user = socket.assigns.current_user
    Notifications.dismiss_notification(user.id, alert_id)
    send(self(), {:alert_dismissed, alert_id})
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "check_on_patient",
        %{"alert_id" => alert_id, "patient_id" => patient_id},
        socket
      ) do
    care_network_memeber = socket.assigns.current_user
    patient = Ankaa.Patients.get_patient!(patient_id)
    alert = Enum.find(socket.assigns.active_alerts, &(&1.alert.id == alert_id))

    Alerts.acknowledge_critical_alert(alert.alert, care_network_memeber.id)
    Ankaa.Notifications.send_checked_on_message(patient, care_network_memeber)
    Logger.info("Check on patient #{patient_id} initiated for alert #{alert_id}")
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "acknowledge_critical",
        %{"alert_id" => alert_id, "patient_id" => patient_id},
        socket
      ) do
    item = Enum.find(socket.assigns.active_alerts, &(&1.alert.id == alert_id))
    care_network_member = socket.assigns.current_user

    case item do
      nil ->
        {:noreply, socket}

      %{alert: found_alert} ->
        # Stop the 15-minute EMS timer
        case Alerts.acknowledge_critical_alert(found_alert, care_network_member.id) do
          {:ok, _} ->
            patient = Ankaa.Patients.get_patient!(patient_id)
            Ankaa.Notifications.send_checked_on_message(patient, care_network_member)
            Notifications.dismiss_notification(care_network_member.id, alert_id)
            send(self(), {:alert_dismissed, alert_id})
            {:noreply, socket}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to acknowledge alert")}
        end
    end
  end

  @impl true
  def handle_event("patient_acknowledge", %{"alert_id" => alert_id}, socket) do
    item = Enum.find(socket.assigns.active_alerts, &(&1.alert.id == alert_id))
    patient_user = socket.assigns.current_user

    case item do
      nil ->
        {:noreply, socket}
      %{alert: found_alert} ->
        Alerts.acknowledge_critical_alert(found_alert, patient_user.id)
        Notifications.dismiss_notification(patient_user.id, alert_id)
        send(self(), {:alert_dismissed, alert_id})

        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="alert-banner-portal">
      <%= for item <- @active_alerts do %>
        <%!-- `item` is a map like %{alert: alert, notification: notification} --%>
        <div
          class={alert_classes(item.alert.severity)}
          id={"alert-#{item.alert.id}"}
          data-alert-id={item.alert.id}
          data-severity={item.alert.severity}
        >
          <div class="flex items-start justify-between p-4">
            <div class="flex items-start">
              <.alert_icon severity={item.alert.severity} />
              <div class="ml-3 flex-1">
                <div class="flex items-center">
                  <h3 class={alert_title_classes(item.alert.severity)}>
                    <%= alert_title(item.alert) %>
                  </h3>
                  <%= if item.alert.severity == "critical" && !item.alert.acknowledged do %>
                    <div class="ml-4 flex items-center text-sm">
                      <div class="animate-pulse h-2 w-2 bg-red-500 rounded-full mr-2"></div>
                      <span class="text-red-700 font-medium">
                        EMS auto-contact in: <span
                          id={"timer-#{item.alert.id}"}
                          phx-hook="CountdownTimer"
                          data-end-time={ems_contact_time(item.alert)}
                        >15:00</span>
                      </span>
                    </div>
                  <% end %>
                </div>
                <div class={alert_message_classes(item.alert.severity)}>
                  <%= item.alert.message %>
                </div>
               <%= if item.alert.severity == "critical" && !item.alert.acknowledged do %>
                  <div class="mt-3 p-3 bg-red-50 border border-red-200 rounded">
                    <%= if Accounts.patient?(@current_user) do %>
                      <%# PATIENT'S VIEW %>
                      <p class="text-sm text-red-800 mb-2">
                        <strong>⚠️ Critical Alert:</strong> A critical issue was detected.
                        Please check your device and contact your care team immediately.
                      </p>
                      <button
                        phx-click="patient_acknowledge"
                        phx-value-alert_id={item.alert.id}
                        phx-target={@myself}
                        class="bg-red-600 text-white px-4 py-2 rounded text-sm font-medium hover:bg-red-700"
                      >
                        ✓ I see this alert.
                      </button>
                    <% else %>
                      <%# CARE NETWORKS'S VIEW %>
                      <p class="text-sm text-red-800 mb-2">
                        <strong>⚠️ Critical Alert:</strong> This alert requires immediate acknowledgment.
                        EMS will be automatically contacted in 15 minutes.
                      </p>
                      <button
                        phx-click="acknowledge_critical"
                        phx-value-alert_id={item.alert.id}
                        phx-value-patient_id={item.alert.patient_id}
                        phx-target={@myself}
                        class="bg-red-600 text-white px-4 py-2 rounded text-sm font-medium hover:bg-red-700"
                      >
                        ✓ Acknowledge & Notify Patient
                      </button>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>
            <div class="flex items-center space-x-2">
              <%= if item.alert.severity == "high" && Accounts.patient?(@current_user) do %>
                <button
                  class="bg-green-100 text-green-800 px-3 py-1 rounded text-sm font-medium hover:bg-green-200"
                  phx-click="dismiss_alert"
                  phx-value-alert_id={item.alert.id}
                  phx-target={@myself}
                >
                  I'm feeling fine
                </button>
              <% end %>
              <%= if item.alert.severity == "high" && @current_user.role in ["doctor", "nurse", "caresupport"] do %>
                <button
                  class="bg-blue-100 text-blue-800 px-3 py-1 rounded text-sm font-medium hover:bg-blue-200"
                  phx-click="check_on_patient"
                  phx-value-alert_id={item.alert.id}
                  phx-value-patient_id={item.alert.patient_id}
                  phx-target={@myself}
                >
                  Check on Patient
                </button>
              <% end %>
              <%= if can_dismiss?(item, @current_user) do %>
                <button
                  class={dismiss_button_classes(item.alert.severity)}
                  phx-click="dismiss_alert"
                  phx-value-alert_id={item.alert.id}
                  phx-target={@myself}
                >
                  <%= dismiss_button_text(item) %>
                </button>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp alert_classes("info"), do: "bg-blue-50 border-l-4 border-blue-400 shadow-sm"
  defp alert_classes("high"), do: "bg-amber-50 border-l-4 border-amber-400 shadow-md"

  defp alert_classes("critical"),
    do: "bg-red-50 border-l-4 border-red-500 shadow-lg animate-pulse"

  defp alert_title_classes("info"), do: "text-sm font-medium text-blue-800"
  defp alert_title_classes("high"), do: "text-sm font-medium text-amber-800"
  defp alert_title_classes("critical"), do: "text-sm font-medium text-red-800"

  defp alert_message_classes("info"), do: "mt-1 text-sm text-blue-700"
  defp alert_message_classes("high"), do: "mt-1 text-sm text-amber-700"
  defp alert_message_classes("critical"), do: "mt-1 text-sm text-red-700"

  defp alert_icon(assigns) do
    ~H"""
    <div class="shrink-0">
      <%= case @severity do %>
        <% "info" -> %>
          <svg class="h-5 w-5 text-blue-400" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
          </svg>
        <% "high" -> %>
          <svg class="h-5 w-5 text-amber-400" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
          </svg>
        <% "critical" -> %>
          <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
          </svg>
      <% end %>
    </div>
    """
  end

  defp alert_title(alert) do
    case alert.severity do
      "info" -> "Information"
      "high" -> "High Priority Alert"
      "critical" -> "🚨 CRITICAL ALERT"
    end
  end

  defp can_dismiss?(%{alert: alert, notification: _notification}, user) do
    case alert.severity do
      "info" -> true
      "high" -> true
      # A critical alert can only be dismissed after it's been acknowledged
      # by a qualified user.
      "critical" -> alert.acknowledged && user.role in ["doctor", "nurse"]
      _ -> false
    end
  end

  defp dismiss_button_classes("info"), do: "text-blue-800 hover:text-blue-900 text-sm"
  defp dismiss_button_classes("high"), do: "text-amber-800 hover:text-amber-900 text-sm"

  defp dismiss_button_classes("critical"),
    do: "text-red-800 hover:text-red-900 text-sm font-medium"

  defp dismiss_button_text(%{alert: alert, notification: notification}) do
    if alert.severity in ["high", "critical"] and notification.status == "unread" do
      "Acknowledge"
    else
      "Dismiss"
    end
  end

  defp ems_contact_time(alert) do
    # Calculate 15 minutes from alert creation
    patient_timezone = alert.patient.timezone

    start_time = DateTime.from_naive!(alert.inserted_at, patient_timezone)

    start_time
    |> DateTime.add(15, :minute)
    |> DateTime.to_iso8601()
  end
end
