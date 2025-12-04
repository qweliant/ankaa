defmodule AnkaaWeb.CareProvider.PatientsLive.Index do
  @moduledoc """
  LiveView for listing patients assigned to the care provider.
  Displays patient name, status, last session, next session, and alert count.
  """
  use AnkaaWeb, :live_view
  use AnkaaWeb, :alert_handling

  alias Ankaa.Patients

  @impl true
  def mount(_params, _session, socket) do
    patients = Patients.list_patients_for_any_role(socket.assigns.current_user)
    {:ok, assign(socket, patients: patients)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-[98%] mx-auto px-2 sm:px-4 lg:px-6 py-8">
      <div class="flex items-center justify-between mb-8">
        <div class="flex items-center gap-2">
          <h1 class="text-2xl font-bold text-slate-900">My Patients</h1>
        </div>
        <div class="flex items-center space-x-4">
          <div class="relative">
            <input
              type="text"
              placeholder="Search patients..."
              class="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md leading-5 bg-white placeholder-gray-500 focus:outline-none focus:placeholder-gray-400 focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
            />
            <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <svg class="h-5 w-5 text-gray-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M8 4a4 4 0 100 8 4 4 0 000-8zM2 8a6 6 0 1110.89 3.476l4.817 4.817a1 1 0 01-1.414 1.414l-4.816-4.816A6 6 0 012 8z" clip-rule="evenodd" />
              </svg>
            </div>
          </div>
          <.link
            navigate={~p"/careprovider/patient/new"}
            class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
            Add Patient or Care Team Member
          </.link>
        </div>
      </div>

      <div class="bg-white shadow overflow-hidden sm:rounded-md">
        <ul role="list" class="divide-y divide-gray-200">
          <%= for patient <- @patients do %>
            <li>
              <.link navigate={~p"/careprovider/patient/#{patient.id}"} class="block hover:bg-gray-50">
                <div class="px-4 py-4 sm:px-6">
                  <div class="flex items-center justify-between">
                    <div class="flex items-center">
                      <div class="shrink-0">
                        <div class="h-10 w-10 rounded-full bg-indigo-100 flex items-center justify-center">
                          <span class="text-indigo-600 font-medium"><%= String.slice(patient.name, 0, 2) %></span>
                        </div>
                      </div>
                      <div class="ml-4">
                        <p class="text-sm font-medium text-indigo-600"><%= patient.name %></p>
                        <div class="flex items-center mt-1">
                          <span class={[
                            "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
                            case patient.status do
                              "In Treatment" -> "bg-green-100 text-green-800"
                              "Stable" -> "bg-blue-100 text-blue-800"
                              _ -> "bg-gray-100 text-gray-800"
                            end
                          ]}>
                            <%= patient.status %>
                          </span>
                          <%= if patient.alerts > 0 do %>
                            <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                              <%= patient.alerts %> Alerts
                            </span>
                          <% end %>
                        </div>
                      </div>
                    </div>
                    <div class="flex flex-col items-end text-sm text-gray-500">
                      <p>Last Session: <%= patient.last_session %></p>
                      <p>Next Session: <%= patient.next_session %></p>
                    </div>
                  </div>
                </div>
              </.link>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end
end
