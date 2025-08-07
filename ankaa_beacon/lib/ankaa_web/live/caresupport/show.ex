defmodule AnkaaWeb.CaringForLive.Show do
  use AnkaaWeb, :live_view
  use AnkaaWeb, :alert_handling

  alias Ankaa.Patients
  alias Ankaa.Sessions

  @impl true
  def mount(%{"id" => patient_id}, _session, socket) do
    current_user = socket.assigns.current_user

    # 1. Fetch all the real data from your contexts
    patient = Patients.get_patient!(patient_id)
    relationship = Patients.get_relationship(current_user, patient)
    latest_session = Sessions.get_latest_session_for_patient(patient)
    recent_sessions = Sessions.list_sessions_for_patient(patient.id)

    # 2. Derive the status and last_check time from the latest session
    {status, last_check} =
      case latest_session do
        %Sessions.Session{status: s, start_time: st} -> {String.capitalize(s), st}
        nil -> {"No Sessions", nil}
      end

    {:ok,
     assign(socket,
       patient: patient,
       relationship: relationship,
       status: status,
       last_check: last_check,
       recent_sessions: recent_sessions,
       show_chat: false
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-[98%] mx-auto px-2 sm:px-4 lg:px-6 py-8">
      <div class="sm:flex sm:items-center sm:justify-between">
        <div class="sm:flex-auto flex items-center gap-2">
          <.link
            navigate={~p"/caresupport/caringfor"}
            class="inline-flex items-center justify-center rounded-full bg-white p-2 text-gray-400 shadow-sm ring-1 ring-gray-900/10 hover:bg-gray-50 hover:text-gray-600 -ml-2"
          >
            <span class="sr-only">Go back</span>
            <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
            </svg>
          </.link>
          <div>
            <h1 class="text-xl font-semibold text-gray-900">Supporting <%= @patient.name %></h1>
            <p class="mt-2 text-sm text-gray-700">
              Detailed information about your role in <%= @patient.name %>'s care.
            </p>
          </div>
        </div>
        <div class="mt-4 sm:mt-0 sm:ml-16 sm:flex-none">
          <button
            type="button"
            phx-click="toggle_chat"
            class="inline-flex items-center justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 sm:w-auto"
          >
            Chat with <%= @patient.name %>
          </button>
        </div>
      </div>

      <div class="mt-8 grid grid-cols-1 gap-6">
        <div class="bg-white shadow rounded-lg p-6">
          <h2 class="text-lg font-medium text-gray-900">Overview</h2>
          <dl class="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div>
              <dt class="text-sm font-medium text-gray-500">Relationship</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @relationship %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Last Session Status</dt>
              <dd class="mt-1">
                <span class={status_badge_color(@status)}>
                  <%= @status %>
                </span>
              </dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Last Session Start</dt>
              <dd class="mt-1 text-sm text-gray-900">
                <%= if @last_check, do: Calendar.strftime(@last_check, "%Y-%m-%d %H:%M"), else: "N/A" %>
              </dd>
            </div>
          </dl>
        </div>

        <div class="bg-white shadow rounded-lg p-6">
          <h2 class="text-lg font-medium text-gray-900">Recent Sessions</h2>
          <div class="mt-4 -mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
            <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
              <table class="min-w-full divide-y divide-gray-300">
                <thead>
                  <tr>
                    <th
                      scope="col"
                      class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0"
                    >
                      Start Time
                    </th>
                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                      Status
                    </th>
                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                      Notes
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-200">
                  <%= for session <- @recent_sessions do %>
                    <tr>
                      <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm text-gray-900 sm:pl-0">
                        <%= Calendar.strftime(session.start_time, "%Y-%m-%d %H:%M") %>
                      </td>
                      <td class="whitespace-nowrap px-3 py-4 text-sm">
                        <span class={status_badge_color(String.capitalize(session.status))}>
                          <%= String.capitalize(session.status) %>
                        </span>
                      </td>
                      <td class="px-3 py-4 text-sm text-gray-500">
                        <%= session.notes || "No notes." %>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      <%= if @show_chat do %>
        ...
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("toggle_chat", _params, socket) do
    {:noreply, assign(socket, show_chat: !socket.assigns.show_chat)}
  end

  defp status_badge_color(status) do
    base_classes = "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium"

    color_classes =
      case status do
        "Ongoing" -> "bg-green-100 text-green-800"
        "Completed" -> "bg-blue-100 text-blue-800"
        "Aborted" -> "bg-red-100 text-red-800"
        _ -> "bg-gray-100 text-gray-800"
      end

    "#{base_classes} #{color_classes}"
  end
end
