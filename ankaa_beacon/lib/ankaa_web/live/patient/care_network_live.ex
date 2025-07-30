defmodule AnkaaWeb.CareNetworkLive do
  use AnkaaWeb, :live_view
  use AnkaaWeb, :patient_layout
  alias Ankaa.Patients

  @impl true
  def mount(_params, _session, socket) do
    patient = socket.assigns.current_user.patient

    network =
      if patient do
        Patients.get_care_network_for_patient(patient)
      else
        []
      end

    IO.inspect(network, label: "Care Network")

    {:ok,
     assign(socket,
       network: network,
       current_path: "/patient/carenetwork",
       show_modal: false,
       selected_member_id: nil
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="flex items-center justify-between mb-8">
        <h1 class="text-2xl font-bold text-slate-900">Care Network</h1>
        <.link
          navigate={~p"/patient/carenetwork/invite"}
          class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          Invite Member
        </.link>
      </div>

      <div class="bg-white shadow overflow-hidden sm:rounded-lg">
        <ul role="list" class="divide-y divide-gray-200">
          <%= for member <- @network do %>
            <li>
              <div class="px-4 py-4 sm:px-6">
                <div class="flex items-center justify-between">
                  <div class="flex items-center">
                    <div class="flex-shrink-0">
                      <span class={[
                        "inline-block h-3 w-3 rounded-full",
                        case member.status do
                          "active" -> "bg-green-400"
                          "pending" -> "bg-yellow-400"
                          "inactive" -> "bg-red-400"
                        end
                      ]}></span>
                    </div>
                    <div class="ml-3">
                      <p class="text-sm font-medium text-gray-900"><%= member.name %></p>
                      <p class="text-sm text-gray-500"><%= member.role %></p>
                    </div>
                  </div>
                  <div class="flex items-center space-x-4">
                    <button
                      phx-click="show_modal"
                      phx-value-id={member.id}
                      class="text-indigo-600 hover:text-indigo-900"
                    >
                      Manage
                    </button>
                  </div>
                </div>
                <div class="mt-2">

                </div>
              </div>
            </li>
          <% end %>
        </ul>
      </div>

      <%= if @show_modal do %>
        <.modal id="member-modal" show>
          <div class="p-6">
            <h3 class="text-lg font-medium text-gray-900">Manage Network Member</h3>
            <div class="mt-4">
              <div class="space-y-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700">Status</label>
                  <select class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md">
                    <option value="active">Active</option>
                    <option value="pending">Pending</option>
                    <option value="inactive">Inactive</option>
                  </select>
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700">Permissions</label>
                  <div class="mt-2 space-y-2">
                    <div class="flex items-center">
                      <input type="checkbox" class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded">
                      <label class="ml-2 block text-sm text-gray-900">View Real-time Dialysis Data</label>
                    </div>
                    <div class="flex items-center">
                      <input type="checkbox" class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded">
                      <label class="ml-2 block text-sm text-gray-900">Receive Critical Alerts</label>
                    </div>
                    <div class="flex items-center">
                      <input type="checkbox" class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded">
                      <label class="ml-2 block text-sm text-gray-900">View Historical Trends</label>
                    </div>
                    <div class="flex items-center">
                      <input type="checkbox" class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded">
                      <label class="ml-2 block text-sm text-gray-900">Initiate Live Monitoring</label>
                    </div>
                    <div class="flex items-center">
                      <input type="checkbox" class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded">
                      <label class="ml-2 block text-sm text-gray-900">Recommend Machine Adjustments</label>
                    </div>
                    <div class="flex items-center">
                      <input type="checkbox" class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded">
                      <label class="ml-2 block text-sm text-gray-900">Set BP Monitoring Parameters</label>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="mt-6 flex justify-between">
              <button
                phx-click="delete_member"
                class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
              >
                Remove Member
              </button>
              <div class="flex space-x-3">
                <button
                  phx-click="close_modal"
                  class="px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  Cancel
                </button>
                <button
                  phx-click="save_changes"
                  class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  Save Changes
                </button>
              </div>
            </div>
          </div>
        </.modal>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("show_modal", %{"id" => id}, socket) do
    {:noreply, assign(socket, show_modal: true, selected_member_id: id)}
  end

  def handle_event("close_modal", _, socket) do
    {:noreply, assign(socket, show_modal: false)}
  end

  def handle_event("save_changes", _, socket) do
    {:noreply, assign(socket, show_modal: false)}
  end

  @impl true
  def handle_event("delete_member", _, socket) do
    # In a real app, we would delete the member from the database
    # For now, we'll just remove it from the dummy data
    network =
      Enum.reject(socket.assigns.network, fn member ->
        member.id == socket.assigns.selected_member_id
      end)

    {:noreply,
     assign(socket,
       network: network,
       show_modal: false,
       selected_member_id: nil
     )}
  end
end
