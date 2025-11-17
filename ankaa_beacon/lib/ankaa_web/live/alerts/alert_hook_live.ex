defmodule AnkaaWeb.AlertHook do
  @moduledoc """
  LiveView hook for managing alert subscriptions and state across the application.
  Integrates with existing UserAuth patterns.

  this shouo
  """

  require Logger
  use AnkaaWeb, :live_view
  alias Ankaa.Alerts

  def on_mount(:subscribe_alerts, _params, _session, socket) do
    if connected?(socket) && socket.assigns[:current_user] do
      user = socket.assigns.current_user

      # Subscribe to user-specific alerts
      Phoenix.PubSub.subscribe(Ankaa.PubSub, "user:#{user.id}:alerts")
      Phoenix.PubSub.subscribe(Ankaa.PubSub, "patient_alerts:#{user.id}:alerts") # possible bug where everyone gets patient alerts absent a guard.

      if user.patient do
        Phoenix.PubSub.subscribe(
          Ankaa.PubSub,
          "patient:#{user.patient.id}:messages"
        )
      else
        Phoenix.PubSub.subscribe(
          Ankaa.PubSub,
          "user:#{user.id}:messages"
        )
      end

      active_alerts = Alerts.get_active_alerts_for_user(user)

      {:cont,
       assign(socket,
         active_alerts: active_alerts,
         dismissed_info_alerts: [],
         toast_message: nil
       )}
    else
      {:cont, assign(socket, active_alerts: [], dismissed_info_alerts: [], toast_message: nil)}
    end
  end

  @impl true
  def handle_event("load_dismissed_alerts", %{"ids" => ids}, socket) do
    # For efficient lookups, convert the list of IDs into a MapSet
    dismissed_alerts = Enum.into(ids, MapSet.new())

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
end
