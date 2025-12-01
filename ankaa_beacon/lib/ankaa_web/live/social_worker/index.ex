defmodule AnkaaWeb.SocialWorker.Index do
  @moduledoc """
  LiveView for displaying the social worker's caseload dashboard.
  """
  use AnkaaWeb, :live_view
  use AnkaaWeb, :alert_handling

  alias Ankaa.Patients

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    # Fetch patients and enrich them with social status
    patients =
      Patients.list_assigned_patients(user)
      |> Enum.map(fn p -> Map.put(p, :social_status, Patients.get_social_status(p)) end)

    {:ok, assign(socket, patients: patients)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-10">
      <div class="md:flex md:items-center md:justify-between mb-8">
        <div class="min-w-0 flex-1">
          <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:truncate sm:text-3xl sm:tracking-tight">
            Social Services Caseload
          </h2>
          <p class="mt-1 text-sm text-gray-500">
            Active Patients: <span class="font-semibold text-gray-900">{length(@patients)}</span>
            |
            Assessments Due:
            <span class="font-semibold text-red-600">
              {Enum.count(@patients, & &1.social_status.assessment_due)}
            </span>
          </p>
        </div>
        <div class="mt-4 flex md:ml-4 md:mt-0">
          <button
            type="button"
            class="inline-flex items-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
          >
            Export CMS Report
          </button>
        </div>
      </div>

      <div class="bg-white shadow-sm ring-1 ring-gray-900/5 sm:rounded-xl overflow-hidden">
        <table class="min-w-full divide-y divide-gray-300">
          <thead class="bg-gray-50">
            <tr>
              <th
                scope="col"
                class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6"
              >
                Patient
              </th>
              <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                Risk Level
              </th>
              <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                Identified Barriers
              </th>
              <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                Status
              </th>
              <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-6">
                <span class="sr-only">Actions</span>
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200 bg-white">
            <%= for patient <- @patients do %>
              <tr>
                <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm sm:pl-6">
                  <div class="flex items-center">
                    <div class="h-10 w-10 shrink-0 rounded-full bg-purple-100 flex items-center justify-center text-purple-700 font-bold">
                      {String.slice(patient.name, 0, 1)}
                    </div>
                    <div class="ml-4">
                      <div class="font-medium text-gray-900">{patient.name}</div>
                      <div class="text-gray-500">{patient.user.email}</div>
                    </div>
                  </div>
                </td>
                <td class="whitespace-nowrap px-3 py-4 text-sm">
                  <%= case patient.social_status.risk do %>
                    <% "high" -> %>
                      <span class="inline-flex items-center rounded-md bg-red-50 px-2 py-1 text-xs font-medium text-red-700 ring-1 ring-inset ring-red-600/10">
                        High Risk
                      </span>
                    <% "medium" -> %>
                      <span class="inline-flex items-center rounded-md bg-yellow-50 px-2 py-1 text-xs font-medium text-yellow-800 ring-1 ring-inset ring-yellow-600/20">
                        Medium
                      </span>
                    <% _ -> %>
                      <span class="inline-flex items-center rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20">
                        Stable
                      </span>
                  <% end %>
                </td>
                <td class="px-3 py-4 text-sm text-gray-500">
                  <div class="flex flex-wrap gap-1">
                    <%= if Enum.empty?(patient.social_status.flags) do %>
                      <span class="text-gray-400 italic">None identified</span>
                    <% else %>
                      <%= for flag <- patient.social_status.flags do %>
                        <span class="inline-flex items-center rounded-full bg-gray-100 px-2.5 py-0.5 text-xs font-medium text-gray-600">
                          {flag}
                        </span>
                      <% end %>
                    <% end %>
                  </div>
                </td>
                <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                  <%= if patient.social_status.assessment_due do %>
                    <div class="flex items-center text-amber-600">
                      <.icon name="hero-clock" class="w-4 h-4 mr-1" /> Assessment Due
                    </div>
                  <% else %>
                    <div class="flex items-center text-green-600">
                      <.icon name="hero-check-circle" class="w-4 h-4 mr-1" /> Up to date
                    </div>
                  <% end %>
                </td>
                <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6">
                  <.link
                    navigate={~p"/case/patient/#{patient.id}"}
                    class="text-purple-600 hover:text-purple-900"
                  >
                    Manage Case<span class="sr-only">, {patient.name}</span>
                  </.link>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
