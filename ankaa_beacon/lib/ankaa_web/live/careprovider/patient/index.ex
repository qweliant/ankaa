defmodule AnkaaWeb.CareProvider.PatientDetailsLive.Index do
  use AnkaaWeb, :live_view

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    # TODO: Replace with actual patient data from database
    patient = %{
      id: String.to_integer(id),
      name: "John Doe",
      age: 45,
      status: "In Treatment",
      last_session: ~D[2024-04-15],
      next_session: ~D[2024-04-17],
      alerts: 0,
      vitals: %{
        blood_pressure: "120/80",
        heart_rate: "72 bpm",
        temperature: "98.6°F"
      },
      treatment_plan: %{
        frequency: "3x per week",
        duration: "4 hours",
        dialysate_flow: "500 mL/min",
        blood_flow: "300 mL/min"
      },
      recent_sessions: [
        %{date: ~D[2024-04-15], duration: "4h", status: "Completed"},
        %{date: ~D[2024-04-12], duration: "4h", status: "Completed"},
        %{date: ~D[2024-04-10], duration: "3.5h", status: "Interrupted"}
      ]
    }

    {:ok, assign(socket, patient: patient, show_chat: false)}
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
              Age: <%= @patient.age %> | Status: <%= @patient.status %>
            </p>
          </div>
        </div>
        <div class="mt-4 sm:mt-0 sm:ml-16 sm:flex-none">
          <button
            type="button"
            phx-click={JS.push("toggle_chat")}
            class="inline-flex items-center justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 sm:w-auto"
          >
            Chat with <%= @patient.name %>
          </button>
        </div>
      </div>

      <div class="mt-8 grid grid-cols-1 gap-6 lg:grid-cols-2">
        <!-- Patient Overview -->
        <div class="bg-white shadow rounded-lg p-6">
          <h2 class="text-lg font-medium text-gray-900">Overview</h2>
          <dl class="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div>
              <dt class="text-sm font-medium text-gray-500">Status</dt>
              <dd class="mt-1">
                <span class={[
                  "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
                  case @patient.status do
                    "In Treatment" -> "bg-green-100 text-green-800"
                    "Stable" -> "bg-blue-100 text-blue-800"
                    _ -> "bg-gray-100 text-gray-800"
                  end
                ]}>
                  <%= @patient.status %>
                </span>
              </dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Next Session</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @patient.next_session %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Last Session</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @patient.last_session %></dd>
            </div>
          </dl>
        </div>

        <!-- Current Vitals -->
        <div class="bg-white shadow rounded-lg p-6">
          <h2 class="text-lg font-medium text-gray-900">Current Vitals</h2>
          <dl class="mt-4 grid grid-cols-2 gap-4">
            <div>
              <dt class="text-sm font-medium text-gray-500">Blood Pressure</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @patient.vitals.blood_pressure %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Heart Rate</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @patient.vitals.heart_rate %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Temperature</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @patient.vitals.temperature %></dd>
            </div>
          </dl>
        </div>

        <!-- Treatment Plan -->
        <div class="bg-white shadow rounded-lg p-6 lg:col-span-2">
          <div class="flex items-center justify-between">
            <h2 class="text-lg font-medium text-gray-900">Treatment Plan</h2>
            <button
              type="button"
              class="inline-flex items-center rounded-md border border-gray-300 bg-white px-3 py-2 text-sm font-medium leading-4 text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
            >
              Edit Plan
            </button>
          </div>
          <dl class="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <div>
              <dt class="text-sm font-medium text-gray-500">Frequency</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @patient.treatment_plan.frequency %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Duration</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @patient.treatment_plan.duration %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Dialysate Flow</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @patient.treatment_plan.dialysate_flow %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Blood Flow</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @patient.treatment_plan.blood_flow %></dd>
            </div>
          </dl>
        </div>

        <!-- Recent Sessions -->
        <div class="bg-white shadow rounded-lg p-6 lg:col-span-2">
          <h2 class="text-lg font-medium text-gray-900">Recent Sessions</h2>
          <div class="mt-4 flow-root">
            <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
              <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
                <table class="min-w-full divide-y divide-gray-300">
                  <thead>
                    <tr>
                      <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0">
                        Date
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
                    <%= for session <- @patient.recent_sessions do %>
                      <tr>
                        <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm text-gray-900 sm:pl-0">
                          <%= session.date %>
                        </td>
                        <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                          <%= session.duration %>
                        </td>
                        <td class="whitespace-nowrap px-3 py-4 text-sm">
                          <span class={[
                            "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
                            case session.status do
                              "Completed" -> "bg-green-100 text-green-800"
                              "Interrupted" -> "bg-yellow-100 text-yellow-800"
                              _ -> "bg-gray-100 text-gray-800"
                            end
                          ]}>
                            <%= session.status %>
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
      </div>

      <!-- Chat Dialog -->
      <%= if @show_chat do %>
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-hidden="true"></div>
        <div class="fixed inset-0 z-10 overflow-y-auto">
          <div class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
            <div class="relative transform overflow-hidden rounded-lg bg-white px-4 pb-4 pt-5 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg sm:p-6">
              <div class="absolute right-0 top-0 hidden pr-4 pt-4 sm:block">
                <button
                  type="button"
                  phx-click={JS.push("toggle_chat")}
                  class="rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
                >
                  <span class="sr-only">Close</span>
                  <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
              <div class="sm:flex sm:items-start">
                <div class="mt-3 text-center sm:mt-0 sm:text-left w-full">
                  <h3 class="text-base font-semibold leading-6 text-gray-900" id="modal-title">Chat with <%= @patient.name %></h3>
                  <div class="mt-4">
                    <div class="h-96 overflow-y-auto border rounded-lg p-4 mb-4">
                      <!-- Chat messages will go here -->
                      <p class="text-sm text-gray-500">Chat feature coming soon...</p>
                    </div>
                    <div class="flex gap-2">
                      <input
                        type="text"
                        placeholder="Type your message..."
                        class="flex-1 rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                      />
                      <button
                        type="button"
                        class="inline-flex items-center justify-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                      >
                        Send
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("toggle_chat", _params, socket) do
    {:noreply, assign(socket, show_chat: !socket.assigns.show_chat)}
  end
end
