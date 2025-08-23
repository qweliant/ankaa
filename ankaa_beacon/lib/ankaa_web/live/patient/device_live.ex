defmodule AnkaaWeb.DeviceLive do
  use AnkaaWeb, :patient_layout
  use AnkaaWeb, :alert_handling

  alias Ankaa.Devices


  @impl true
  def mount(_params, _session, socket) do
    devices = Devices.list_devices_for_patient(socket.assigns.current_user.patient.id)
    {:ok, assign(socket, devices: devices, current_path: "/patient/devices")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    device = Devices.get_device!(id)
    {:ok, _} = Devices.delete_device(device)

    # Refetch the list of devices to update the UI
    devices = Devices.list_devices_for_patient(socket.assigns.current_user.patient.id)
    {:noreply, assign(socket, :devices, devices)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="flex items-center justify-between mb-8">
        <h1 class="text-2xl font-bold text-slate-900">My Devices</h1>
        <.link
          navigate={~p"/patient/devices/new"}
          class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          Add Device
        </.link>
      </div>

      <div class="bg-white shadow overflow-hidden sm:rounded-md">
        <ul role="list" class="divide-y divide-gray-200">
          <%= for device <- @devices do %>
            <li>
              <div class="px-4 py-4 sm:px-6">
                <div class="flex items-center justify-between">
                  <div class="flex items-center">
                    <p class="text-sm font-medium text-indigo-600 truncate">
                      <%= device.type |> String.replace("_", " ") |> String.capitalize() %>
                    </p>
                    <p class="ml-2 text-sm text-gray-500">
                      Scenario: <%= device.simulation_scenario %>
                    </p>
                  </div>
                  <div class="flex items-center space-x-4">
                    <.link
                      navigate={~p"/patient/devices/#{device.id}/edit"}
                      class="text-indigo-600 hover:text-indigo-900"
                    >
                      Edit
                    </.link>
                    <.link
                      phx-click="delete"
                      phx-value-id={device.id}
                      data-confirm="Are you sure?"
                      class="text-red-600 hover:text-red-900"
                    >
                      Delete
                    </.link>
                  </div>
                </div>
              </div>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end
end
