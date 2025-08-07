defmodule AnkaaWeb.CareProvider.PatientDetailsLive.Index do
  use AnkaaWeb, :live_view
  use AnkaaWeb, :alert_handling

  alias Ankaa.Patients
  alias Ankaa.Sessions

  @impl true
  def mount(%{"id" => patient_id}, _session, socket) do
    patient = Patients.get_patient!(patient_id)
    latest_session = Sessions.get_latest_session_for_patient(patient)
    recent_sessions = Sessions.list_sessions_for_patient(patient.id)

    age = calculate_age(patient.date_of_birth)

    {status, last_session} =
      case latest_session do
        %Sessions.Session{status: s, start_time: st} -> {String.capitalize(s), st}
        nil -> {"No Sessions", nil}
      end

    vitals = %{
      blood_pressure: "135/88 mmHg",
      heart_rate: "82 bpm",
      oxygen_saturation: "97%",
      last_updated: DateTime.utc_now() |> DateTime.add(-15, :minute)
    }

    treatment_plan = %{
      frequency: "3x per week (Mon, Wed, Fri)",
      duration: "4 hours",
      dialysate_flow: "500 mL/min",
      blood_flow: "400 mL/min",
      notes: "Patient is stable on current settings. Monitor for cramping."
    }

    {:ok,
     assign(socket,
       patient: patient,
       age: age,
       status: status,
       last_session: last_session,
       recent_sessions: recent_sessions,
       vitals: vitals,
       treatment_plan: treatment_plan,
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
            navigate={~p"/careprovider/patients"}
            class="inline-flex items-center justify-center rounded-full bg-white p-2 text-gray-400 shadow-sm ring-1 ring-gray-900/10 hover:bg-gray-50 hover:text-gray-600 -ml-2"
          >
            <span class="sr-only">Go back</span>
            <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
            </svg>
          </.link>
          <div>
            <h1 class="text-xl font-semibold text-gray-900">Patient Details: <%= @patient.name %></h1>
            <p class="mt-2 text-sm text-gray-700">
              Age: <%= @age %> | Status: <%= @status %>
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

      <div class="mt-8 grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div class="bg-white shadow rounded-lg p-6">
          <h2 class="text-lg font-medium text-gray-900">Overview</h2>
          <dl class="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2">
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
                <%= if @last_session, do: Calendar.strftime(@last_session, "%Y-%m-%d %H:%M"), else: "N/A" %>
              </dd>
            </div>
          </dl>
        </div>

        <div class="bg-white shadow rounded-lg p-6">
          <h2 class="text-lg font-medium text-gray-900">Current Vitals</h2>
          <p class="text-xs text-gray-400">Last updated: <%= Calendar.strftime(@vitals.last_updated, "%H:%M") %></p>
          <dl class="mt-4 grid grid-cols-3 gap-4">
            <div>
              <dt class="text-sm font-medium text-gray-500">Blood Pressure</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @vitals.blood_pressure %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Heart Rate</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @vitals.heart_rate %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">O₂ Saturation</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @vitals.oxygen_saturation %></dd>
            </div>
          </dl>
        </div>

        <div class="bg-white shadow rounded-lg p-6 lg:col-span-2">
          <h2 class="text-lg font-medium text-gray-900">Treatment Plan</h2>
          <dl class="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <div>
              <dt class="text-sm font-medium text-gray-500">Frequency</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @treatment_plan.frequency %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Duration</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @treatment_plan.duration %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Dialysate Flow</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @treatment_plan.dialysate_flow %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Blood Flow</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @treatment_plan.blood_flow %></dd>
            </div>
            <div class="sm:col-span-2 lg:col-span-4">
              <dt class="text-sm font-medium text-gray-500">Notes</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @treatment_plan.notes %></dd>
            </div>
          </dl>
        </div>

        <div class="bg-white shadow rounded-lg p-6 lg:col-span-2">
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
                      Duration
                    </th>
                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                      Status
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-200">
                  <%= for session <- @recent_sessions do %>
                    <tr>
                      <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm text-gray-900 sm:pl-0">
                        <%= Calendar.strftime(session.start_time, "%Y-%m-%d %H:%M") %>
                      </td>
                      <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                        <%= format_session_duration(session) %>
                      </td>
                      <td class="whitespace-nowrap px-3 py-4 text-sm">
                        <span class={status_badge_color(String.capitalize(session.status))}>
                          <%= String.capitalize(session.status) %>
                        </span>
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

  defp calculate_age(nil), do: "N/A"

  defp calculate_age(date_of_birth) do
    today = Date.utc_today()
    age = today.year - date_of_birth.year

    if {today.month, today.day} < {date_of_birth.month, date_of_birth.day} do
      age - 1
    else
      age
    end
  end

  defp format_session_duration(%Sessions.Session{start_time: start, end_time: stop})
       when not is_nil(stop) do
    diff_seconds = DateTime.diff(stop, start, :second)
    hours = div(diff_seconds, 3600)
    minutes = rem(div(diff_seconds, 60), 60)
    "#{hours}h #{minutes}m"
  end

  defp format_session_duration(_session), do: "Ongoing"

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
