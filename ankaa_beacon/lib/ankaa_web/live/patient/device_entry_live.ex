defmodule AnkaaWeb.DeviceEntryLive do
  use AnkaaWeb, :live_view
  use AnkaaWeb, :patient_layout

  alias Ankaa.Patients
  alias Ankaa.Patients.Device

  @impl true
  def mount(_params, _session, socket) do
    changeset = Device.changeset(%Device{}, %{})
    {:ok, assign(socket, changeset: changeset, current_path: "/patient/devices/new")}
  end

  @impl true
  def handle_event("validate", %{"device" => device_params}, socket) do
    changeset =
      %Device{}
      |> Device.changeset(device_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event("save", %{"device" => device_params}, socket) do
    attrs = Map.put(device_params, "patient_id", socket.assigns.current_user.patient.id)

    case Patients.create_device(attrs) do
      {:ok, _device} ->
        {:noreply,
         socket
         |> put_flash(:info, "Device registered successfully")
         |> push_navigate(to: ~p"/patient/devices")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="md:grid md:grid-cols-3 md:gap-6">
        <div class="md:col-span-1">
          <div class="px-4 sm:px-0">
            <h3 class="text-lg font-medium leading-6 text-gray-900">Register New Device</h3>
            <p class="mt-1 text-sm text-gray-600">
              Enter your device information below. This will help us connect your device to your account.
            </p>
          </div>
        </div>

        <div class="mt-5 md:mt-0 md:col-span-2">
          <.form
            for={@changeset}
            id="device-form"
            phx-change="validate"
            phx-submit="save"
            class="space-y-6"
          >
            <div class="shadow sm:rounded-md sm:overflow-hidden">
              <div class="px-4 py-5 bg-white space-y-6 sm:p-6">
                <div>
                  <label for="device_type" class="block text-sm font-medium text-gray-700">
                    Device Type
                  </label>
                  <select
                    id="device_type"
                    name="device[type]"
                    class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                  >
                    <option value="">Select a device type</option>
                    <option value="dialysis" selected={Ecto.Changeset.get_field(@changeset, :type) == "dialysis"}>Dialysis Machine</option>
                    <option value="blood_pressure" selected={Ecto.Changeset.get_field(@changeset, :type) == "blood_pressure"}>Blood Pressure Monitor</option>
                  </select>
                  <%= for error <- Ecto.Changeset.get_field(@changeset, :errors, []) |> Keyword.get_values(:type) do %>
                    <p class="mt-2 text-sm text-red-600"><%= translate_error(error) %></p>
                  <% end %>
                </div>

                <div>
                  <label for="device_id" class="block text-sm font-medium text-gray-700">
                    Device ID
                  </label>
                  <input
                    type="text"
                    name="device[device_id]"
                    id="device_id"
                    value={Ecto.Changeset.get_field(@changeset, :device_id)}
                    class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
                  />
                  <%= for error <- Ecto.Changeset.get_field(@changeset, :errors, []) |> Keyword.get_values(:device_id) do %>
                    <p class="mt-2 text-sm text-red-600"><%= translate_error(error) %></p>
                  <% end %>
                </div>

                <div>
                  <label for="model" class="block text-sm font-medium text-gray-700">
                    Model (Optional)
                  </label>
                  <input
                    type="text"
                    name="device[model]"
                    id="model"
                    value={Ecto.Changeset.get_field(@changeset, :model)}
                    class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
                  />
                </div>
              </div>

              <div class="px-4 py-3 bg-gray-50 text-right sm:px-6">
                <.link
                  navigate={~p"/patient/devices"}
                  class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  Cancel
                </.link>
                <button
                  type="submit"
                  class="ml-3 inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  Register Device
                </button>
              </div>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end
end
