defmodule AnkaaWeb.AlertHook do
  @moduledoc """
  LiveView hook for managing alert subscriptions and state across the application.
  Integrates with existing UserAuth patterns.
  """

  use AnkaaWeb, :live_view
  alias Ankaa.Alerts

  def on_mount(:subscribe_alerts, _params, _session, socket) do
    if connected?(socket) && socket.assigns[:current_user] do
      user = socket.assigns.current_user

      # Subscribe to user-specific alerts
      Phoenix.PubSub.subscribe(Ankaa.PubSub, "user:#{user.id}:alerts")

      # Subscribe to role-based alerts
      # role_topic = get_role_topic(user)
      # if role_topic, do: Phoenix.PubSub.subscribe(Ankaa.PubSub, role_topic)

      # Fetch any alerts that are already active for this provider's patients.
      active_alerts = Alerts.get_active_alerts_for_user(user)

      {:cont,
       assign(socket,
         active_alerts: active_alerts,
         dismissed_info_alerts: []
       )}
    else
      # If not connected or no user, assign empty lists.
      {:cont, assign(socket, active_alerts: [], dismissed_info_alerts: [])}
    end
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

  # defp get_dismissed_info_alerts_from_session(_socket) do
  #   # Get from session storage on client side - we'll handle this in the component
  #   []
  # end

  # defp get_role_topic(user) do
  #   case user.role do
  #     "doctor" -> "role:doctors:alerts"
  #     "nurse" -> "role:nurses:alerts"
  #     "caresupport" -> "role:caresupport:alerts"
  #     "patient" -> "role:patients:alerts"
  #     _ -> nil
  #   end
  # end

  # defp subscribe_to_patient_alerts(patient_id) do
  #   Phoenix.PubSub.subscribe(Ankaa.PubSub, "patient:#{patient_id}:alerts")
  # end

  # defp filter_dismissed_alerts(alerts, dismissed_ids) do
  #   Enum.reject(alerts, fn alert ->
  #     alert.severity == "info" && alert.id in dismissed_ids
  #   end)
  # end
end
