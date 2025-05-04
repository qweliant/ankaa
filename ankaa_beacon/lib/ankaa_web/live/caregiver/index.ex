defmodule AnkaaWeb.CaringForLive.Index do
  use AnkaaWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # TODO: Replace with actual data from database
    patients = [
      %{
        id: 1,
        name: "John Doe",
        relationship: "Father",
        status: "In Treatment",
        next_session: ~D[2024-04-17],
        last_check: ~U[2024-04-16 08:30:00Z],
        needs_attention: false
      },
      %{
        id: 2,
        name: "Mary Johnson",
        relationship: "Mother",
        status: "Stable",
        next_session: ~D[2024-04-18],
        last_check: ~U[2024-04-16 09:15:00Z],
        needs_attention: true
      }
    ]

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
                    <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6">
                      Patient
                    </th>
                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                      Relationship
                    </th>
                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                      Status
                    </th>
                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                      Next Session
                    </th>
                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                      Last Check
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-200 bg-white">
                  <%= for patient <- @patients do %>
                    <tr
                      class={"cursor-pointer #{if patient.needs_attention, do: "bg-red-50 hover:bg-red-100", else: "hover:bg-gray-50"}"}
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
                        <span class={[
                          "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
                          case patient.status do
                            "In Treatment" -> "bg-green-100 text-green-800"
                            "Stable" -> "bg-blue-100 text-blue-800"
                            _ -> "bg-gray-100 text-gray-800"
                          end
                        ]}>
                          <%= patient.status %>
                        </span>
                      </td>
                      <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                        <%= patient.next_session %>
                      </td>
                      <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                        <%= Calendar.strftime(patient.last_check, "%Y-%m-%d %H:%M") %>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      <%= if Enum.any?(@patients, & &1.needs_attention) do %>
        <div class="mt-4 rounded-md bg-red-50 p-4">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clip-rule="evenodd" />
              </svg>
            </div>
            <div class="ml-3">
              <h3 class="text-sm font-medium text-red-800">Attention Required</h3>
              <div class="mt-2 text-sm text-red-700">
                <p>Some patients need your attention. Please check their status and take necessary actions.</p>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
