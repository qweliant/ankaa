# defmodule AnkaaWeb.AlertBanner do
#   use AnkaaWeb, :live_component
#   alias Ankaa.Alerts
#   alias Ankaa.Accounts.User

#   @impl true
#   def update(assigns, socket) do
#     {:ok, assign(socket, assigns)}
#   end

#   @impl true
#   def handle_event("dismiss_alert", %{"alert_id" => alert_id}, socket) do
#     alert = Enum.find(socket.assigns.active_alerts, &(&1.id == String.to_integer(alert_id)))
#     user = socket.assigns.current_user

#     case alert.severity do
#       "info" ->
#         # INFO alerts: Store dismissal in session storage (handled by client-side)
#         # Also remove from server state
#         send(self(), {:alert_dismissed, alert.id})
#         {:noreply, socket}

#       "high" when User.is_patient?(user) ->
#         # HIGH alerts: Patients can self-dismiss but it's tracked in DB
#         case Alerts.dismiss_alert(alert.id, user.id, "patient_self_dismissal") do
#           {:ok, _} ->
#             send(self(), {:alert_dismissed, alert.id})
#             {:noreply, socket}

#           {:error, _} ->
#             {:noreply, put_flash(socket, :error, "Failed to dismiss alert")}
#         end

#       "high" ->
#         # HIGH alerts: Care providers can dismiss normally
#         case Alerts.dismiss_alert(alert.id, user.id, "care_provider_dismissal") do
#           {:ok, _} ->
#             send(self(), {:alert_dismissed, alert.id})
#             {:noreply, socket}

#           {:error, _} ->
#             {:noreply, put_flash(socket, :error, "Failed to dismiss alert")}
#         end

#       "critical" ->
#         # CRITICAL alerts: Only doctors/nurses can dismiss with acknowledgment
#         if user.role in ["doctor", "nurse"] do
#           case Alerts.dismiss_alert(alert.id, user.id, "clinical_dismissal") do
#             {:ok, _} ->
#               send(self(), {:alert_dismissed, alert.id})
#               {:noreply, socket}

#             {:error, _} ->
#               {:noreply, put_flash(socket, :error, "Failed to dismiss alert")}
#           end
#         else
#           {:noreply,
#            put_flash(socket, :error, "Only doctors and nurses can dismiss critical alerts")}
#         end
#     end
#   end

#   @impl true
#   def handle_event(
#         "check_on_patient",
#         %{"alert_id" => alert_id, "patient_id" => patient_id},
#         socket
#       ) do
#     # This would integrate with your existing care network/communication system
#     # Start the chat → call → EMS escalation flow

#     # For now, just show that the check was initiated
#     send(
#       self(),
#       {:patient_check_initiated, String.to_integer(alert_id), String.to_integer(patient_id)}
#     )

#     {:noreply, socket}
#   end

#   @impl true
#   def handle_event("acknowledge_critical", %{"alert_id" => alert_id}, socket) do
#     alert = Enum.find(socket.assigns.active_alerts, &(&1.id == String.to_integer(alert_id)))

#     # Stop the 15-minute EMS timer
#     case Alerts.acknowledge_critical_alert(alert.id, socket.assigns.current_user.id) do
#       {:ok, _} ->
#         send(self(), {:critical_acknowledged, alert.id})
#         {:noreply, socket}

#       {:error, _} ->
#         {:noreply, put_flash(socket, :error, "Failed to acknowledge alert")}
#     end
#   end

#   @impl true
#   def render(assigns) do
#     ~H"""
#     <div id="alert-banner-portal">
#       <%= for alert <- @active_alerts do %>
#         <div class={alert_classes(alert.severity)}
#              id={"alert-#{alert.id}"}
#              data-alert-id={alert.id}
#              data-severity={alert.severity}>

#           <div class="flex items-start justify-between p-4">
#             <div class="flex items-start">
#               <div class="flex-shrink-0">
#                 <%= alert_icon(alert.severity) %>
#               </div>

#               <div class="ml-3 flex-1">
#                 <div class="flex items-center">
#                   <h3 class={alert_title_classes(alert.severity)}>
#                     <%= alert_title(alert) %>
#                   </h3>

#                   <%= if alert.severity == "critical" && !alert.acknowledged do %>
#                     <div class="ml-4 flex items-center text-sm">
#                       <div class="animate-pulse h-2 w-2 bg-red-500 rounded-full mr-2"></div>
#                       <span class="text-red-700 font-medium">
#                         EMS auto-contact in: <span id={"timer-#{alert.id}"} phx-hook="CountdownTimer" data-end-time={ems_contact_time(alert)}>15:00</span>
#                       </span>
#                     </div>
#                   <% end %>
#                 </div>

#                 <div class={alert_message_classes(alert.severity)}>
#                   <%= alert.message %>
#                 </div>

#                 <%= if alert.severity == "critical" && !alert.acknowledged do %>
#                   <div class="mt-3 p-3 bg-red-50 border border-red-200 rounded">
#                     <p class="text-sm text-red-800 mb-2">
#                       <strong>⚠️ Critical Alert:</strong> This alert requires immediate acknowledgment.
#                       EMS will be automatically contacted in 15 minutes if not acknowledged.
#                     </p>
#                     <button phx-click="acknowledge_critical"
#                             phx-value-alert_id={alert.id}
#                             phx-target={@myself}
#                             class="bg-red-600 text-white px-4 py-2 rounded text-sm font-medium hover:bg-red-700">
#                       ✓ Acknowledge & Stop EMS Timer
#                     </button>
#                   </div>
#                 <% end %>
#               </div>
#             </div>

#             <div class="flex items-center space-x-2">
#               <%= if alert.severity == "high" && User.is_patient?(@current_user) do %>
#                 <button class="bg-green-100 text-green-800 px-3 py-1 rounded text-sm font-medium hover:bg-green-200"
#                         phx-click="dismiss_alert"
#                         phx-value-alert_id={alert.id}
#                         phx-target={@myself}>
#                   I'm feeling fine
#                 </button>
#               <% end %>

#               <%= if alert.severity == "high" && @current_user.role in ["doctor", "nurse", "caresupport"] do %>
#                 <button class="bg-blue-100 text-blue-800 px-3 py-1 rounded text-sm font-medium hover:bg-blue-200"
#                         phx-click="check_on_patient"
#                         phx-value-alert_id={alert.id}
#                         phx-value-patient_id={alert.patient_id}
#                         phx-target={@myself}>
#                   Check on Patient
#                 </button>
#               <% end %>

#               <%= if can_dismiss_alert?(alert, @current_user) do %>
#                 <button class={dismiss_button_classes(alert.severity)}
#                         phx-click="dismiss_alert"
#                         phx-value-alert_id={alert.id}
#                         phx-target={@myself}>
#                   <%= dismiss_button_text(alert.severity) %>
#                 </button>
#               <% end %>
#             </div>
#           </div>
#         </div>
#       <% end %>
#     </div>
#     """
#   end

#   defp alert_classes("info"), do: "bg-blue-50 border-l-4 border-blue-400 shadow-sm"
#   defp alert_classes("high"), do: "bg-amber-50 border-l-4 border-amber-400 shadow-md"

#   defp alert_classes("critical"),
#     do: "bg-red-50 border-l-4 border-red-500 shadow-lg animate-pulse"

#   defp alert_title_classes("info"), do: "text-sm font-medium text-blue-800"
#   defp alert_title_classes("high"), do: "text-sm font-medium text-amber-800"
#   defp alert_title_classes("critical"), do: "text-sm font-medium text-red-800"

#   defp alert_message_classes("info"), do: "mt-1 text-sm text-blue-700"
#   defp alert_message_classes("high"), do: "mt-1 text-sm text-amber-700"
#   defp alert_message_classes("critical"), do: "mt-1 text-sm text-red-700"

#   defp alert_icon("info") do
#     ~H"""
#     <svg class="h-5 w-5 text-blue-400" viewBox="0 0 20 20" fill="currentColor">
#       <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
#     </svg>
#     """
#   end

#   defp alert_icon("high") do
#     ~H"""
#     <svg class="h-5 w-5 text-amber-400" viewBox="0 0 20 20" fill="currentColor">
#       <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
#     </svg>
#     """
#   end

#   defp alert_icon("critical") do
#     ~H"""
#     <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
#       <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
#     </svg>
#     """
#   end

#   defp alert_title(alert) do
#     case alert.severity do
#       "info" -> "Information"
#       "high" -> "High Priority Alert"
#       "critical" -> "🚨 CRITICAL ALERT"
#     end
#   end

#   defp can_dismiss_alert?(alert, user) do
#     case alert.severity do
#       "info" -> true
#       # Patients and care providers can both dismiss
#       "high" -> true
#       "critical" -> user.role in ["doctor", "nurse"]
#     end
#   end

#   defp dismiss_button_classes("info"), do: "text-blue-800 hover:text-blue-900 text-sm"
#   defp dismiss_button_classes("high"), do: "text-amber-800 hover:text-amber-900 text-sm"

#   defp dismiss_button_classes("critical"),
#     do: "text-red-800 hover:text-red-900 text-sm font-medium"

#   defp dismiss_button_text("info"), do: "×"
#   defp dismiss_button_text("high"), do: "Dismiss"
#   defp dismiss_button_text("critical"), do: "Dismiss"

#   defp ems_contact_time(alert) do
#     # Calculate 15 minutes from alert creation
#     alert.inserted_at
#     |> DateTime.add(15, :minute)
#     |> DateTime.to_iso8601()
#   end
# end
