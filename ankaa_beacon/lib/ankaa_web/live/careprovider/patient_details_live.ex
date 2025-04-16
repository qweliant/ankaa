defmodule AnkaaWeb.CareProvider.PatientDetailsLive do
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

    {:ok, assign(socket, patient: patient)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="mb-8">
        <.link navigate={~p"/careprovider/patients"} class="text-indigo-600 hover:text-indigo-900">
          ← Back to Patients
        </.link>
      </div>

      <div class="bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6 flex justify-between items-center">
          <div>
            <h3 class="text-lg leading-6 font-medium text-gray-900">Patient Information</h3>
            <p class="mt-1 max-w-2xl text-sm text-gray-500">Personal details and treatment information.</p>
          </div>
          <div class="flex space-x-4">
            <button class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
              Edit Treatment Plan
            </button>
            <button class="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
              Start Session
            </button>
          </div>
        </div>

        <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
          <dl class="grid grid-cols-1 gap-x-4 gap-y-8 sm:grid-cols-2">
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Full name</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @patient.name %></dd>
            </div>
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Age</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @patient.age %></dd>
            </div>
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Status</dt>
              <dd class="mt-1">
                <span class={[
                  "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
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
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Next Session</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @patient.next_session %></dd>
            </div>
          </dl>
        </div>

        <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
          <h4 class="text-lg font-medium text-gray-900 mb-4">Current Vitals</h4>
          <dl class="grid grid-cols-1 gap-x-4 gap-y-8 sm:grid-cols-3">
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Blood Pressure</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @patient.vitals.blood_pressure %></dd>
            </div>
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Heart Rate</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @patient.vitals.heart_rate %></dd>
            </div>
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Temperature</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @patient.vitals.temperature %></dd>
            </div>
          </dl>
        </div>

        <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
          <h4 class="text-lg font-medium text-gray-900 mb-4">Treatment Plan</h4>
          <dl class="grid grid-cols-1 gap-x-4 gap-y-8 sm:grid-cols-2 lg:grid-cols-4">
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

        <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
          <h4 class="text-lg font-medium text-gray-900 mb-4">Recent Sessions</h4>
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                  <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Duration</th>
                  <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <%= for session <- @patient.recent_sessions do %>
                  <tr>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900"><%= session.date %></td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900"><%= session.duration %></td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <span class={[
                        "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
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
    """
  end
end
