defmodule AnkaaWeb.AlertHook do
  @moduledoc """
  LiveView hook for managing alert subscriptions and state across the application.
  Integrates with existing UserAuth patterns.
  """

  use AnkaaWeb, :live_view
  alias Ankaa.Alerts
  alias Ankaa.Accounts

  def on_mount(:subscribe_alerts, _params, _session, socket) do
    if connected?(socket) && socket.assigns[:current_user] do
      user = socket.assigns.current_user

      # Subscribe to user-specific alerts
      Phoenix.PubSub.subscribe(Ankaa.PubSub, "user:#{user.id}:alerts")

      # Subscribe to role-based alerts
      role_topic = get_role_topic(user)
      if role_topic, do: Phoenix.PubSub.subscribe(Ankaa.PubSub, role_topic)

      # For care providers, also subscribe to their patients' alerts
      if user.role in ["doctor", "nurse", "caresupport"] do
        patient_ids = get_patient_ids_for_care_provider(user)
        Enum.each(patient_ids, &subscribe_to_patient_alerts/1)
      end

      # Get and filter alerts
      active_alerts = Alerts.get_active_alerts_for_user(user)
      # dismissed_info_alerts = get_dismissed_info_alerts_from_session(socket)

      # filtered_alerts = filter_dismissed_alerts(active_alerts, dismissed_info_alerts)

      {:cont,
       assign(socket,
         active_alerts: active_alerts,
         dismissed_info_alerts: []
       )}
    else
      {:cont, assign(socket, active_alerts: [], dismissed_info_alerts: [])}
    end
  end

  # Handle new alert broadcasts
  def handle_info({:new_alert, alert}, socket) do
    # Skip if INFO alert was already dismissed in this session
    if alert.severity == "info" && alert.id in socket.assigns.dismissed_info_alerts do
      {:noreply, socket}
    else
      {:noreply, update(socket, :active_alerts, fn alerts -> [alert | alerts] end)}
    end
  end

  # Handle alert dismissals
  def handle_info({:alert_dismissed, alert_id}, socket) do
    {:noreply,
     update(socket, :active_alerts, fn alerts ->
       Enum.reject(alerts, &(&1.id == alert_id))
     end)}
  end

  # Handle EMS escalations
  def handle_info({:ems_escalation, alert_id}, socket) do
    # Update alert to show EMS has been contacted
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

  def handle_event("load_dismissed_alerts", %{"ids" => ids}, socket) do
    # For efficient lookups, convert the list of IDs into a MapSet
    dismissed_alerts = Enum.into(ids, MapSet.new())

    # Remove any alerts that the user has already dismissed in this session
    filtered_alerts =
      Enum.reject(socket.assigns.active_alerts, fn alert ->
        alert.id in dismissed_alerts
      end)

    {:noreply,
     assign(socket,
       # Update the visible alerts
       active_alerts: filtered_alerts,
       # Store the set of dismissed IDs for later checks
       dismissed_info_alerts: dismissed_alerts
     )}
  end

  defp get_patient_ids_for_care_provider(user) do
    # This would integrate with your existing care network relationships
    # Assuming you have a function like this in your Patients context
    Ankaa.Patients.get_patient_ids_for_care_provider(user.id)
  end

  defp get_dismissed_info_alerts_from_session(socket) do
    # Get from session storage on client side - we'll handle this in the component
    []
  end

  defp get_role_topic(user) do
    case user.role do
      "doctor" -> "role:doctors:alerts"
      "nurse" -> "role:nurses:alerts"
      "caresupport" -> "role:caresupport:alerts"
      "patient" -> "role:patients:alerts"
      _ -> nil
    end
  end

  defp subscribe_to_patient_alerts(patient_id) do
    Phoenix.PubSub.subscribe(Ankaa.PubSub, "patient:#{patient_id}:alerts")
  end

  defp filter_dismissed_alerts(alerts, dismissed_ids) do
    Enum.reject(alerts, fn alert ->
      alert.severity == "info" && alert.id in dismissed_ids
    end)
  end
end
