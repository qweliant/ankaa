defmodule AnkaaWeb.CaringForLive.Index do
  use AnkaaWeb, :live_view

  alias Ankaa.Patients
  @impl true
  def mount(_params, _session, socket) do
    # TODO: Replace with actual data from database
    patients = Patients.list_patients_for_any_role(socket.assigns.current_user)

    {:ok, assign(socket, patients: patients)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="sm:flex sm:items-center">
        <div class="sm:flex-auto">
          <h1 class="text-xl font-semibold text-gray-900">Providing Support for</h1>
          <p class="mt-2 text-sm text-gray-700">
            A list of members you support and their current status.
          </p>
        </div>
      </div>

      <div class="mt-8 flex flex-col">
        <div class="-my-2 -mx-4 overflow-x-auto sm:-mx-6 lg:-mx-8">
          <div class="inline-block min-w-full py-2 align-middle md:px-6 lg:px-8">
            <div class="overflow-hidden shadow ring-1 ring-black ring-opacity-5 md:rounded-lg">
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
                      Relationship
                    </th>
                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                      Last Session Status
                    </th>
                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                      Last Session Start
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-200 bg-white">
                  <%= for patient <- @patients do %>
                    <tr
                      class="cursor-pointer hover:bg-gray-50"
                      phx-click={JS.navigate(~p"/caresupport/caringfor/#{patient.id}")}
                    >
                      <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm sm:pl-6">
                        <div class="flex items-center">
                          <div class="h-10 w-10 flex-shrink-0">
                            <span class="inline-flex h-10 w-10 items-center justify-center rounded-full bg-gray-500">
                              <span class="text-xl font-medium leading-none text-white">
                                <%= String.first(patient.name) %>
                              </span>
                            </span>
                          </div>
                          <div class="ml-4">
                            <div class="font-medium text-gray-900"><%= patient.name %></div>
                          </div>
                        </div>
                      </td>
                      <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                        <%= patient.relationship %>
                      </td>
                      <td class="whitespace-nowrap px-3 py-4 text-sm">
                        <span class={status_badge_color(patient.status)}>
                          <%= patient.status %>
                        </span>
                      </td>
                      <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                        <%= if patient.last_check do %>
                          <%= Calendar.strftime(patient.last_check, "%Y-%m-%d %H:%M") %>
                        <% else %>
                          N/A
                        <% end %>
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
    """
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
