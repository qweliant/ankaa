defmodule AnkaaWeb.DeviceEditLive do
  use AnkaaWeb, :patient_layout

  alias Ankaa.Devices

  @bp_scenarios [
    "Normal": "Normal",
    "High Systolic": "HighSystolic",
    "Low Diastolic": "LowDiastolic",
    "Irregular Heartbeat": "IrregularHeartbeat"
  ]
  @dialysis_scenarios [
    "Normal": "Normal",
    "High Venous Pressure": "HighVP",
    "Low Blood Flow": "LowBFR"
  ]

  @impl true
  def mount(_params, _session, socket) do
  {:ok,
    socket
    |> assign(current_path: "/patient/devices")
    # Add the missing scenario lists to the assigns
    |> assign(bp_scenarios: @bp_scenarios)
    |> assign(dialysis_scenarios: @dialysis_scenarios)}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    device = Devices.get_device!(id)
    changeset = Devices.change_device(device)

    socket =
      socket
      |> assign(:page_title, "Edit Device")
      |> assign(:device, device)
      |> assign(:form, to_form(changeset))

    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"device" => device_params}, socket) do
    device = socket.assigns.device

    case Devices.update_device(device, device_params) do
      {:ok, _updated_device} ->
        {:noreply,
         socket
         |> put_flash(:info, "Device updated successfully.")
         |> push_navigate(to: ~p"/patient/devices")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto py-8">
      <.link navigate={~p"/patient/devices"} class="text-sm font-semibold text-indigo-600 mb-4 inline-block">
        &larr; Back to Device List
      </.link>

      <div class="bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900">
            Edit Device Scenario
          </h3>
          <p class="mt-1 max-w-2xl text-sm text-gray-500">
            Update the simulated behavior for this device.
          </p>
        </div>
        <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
          <.simple_form for={@form} phx-submit="save">
            <%= if @device.type == "blood_pressure" do %>
              <.input
                field={@form[:simulation_scenario]}
                type="select"
                label="Simulation Scenario"
                options={@bp_scenarios}
                required
              />
            <% end %>

            <%= if @device.type == "dialysis" do %>
              <.input
                field={@form[:simulation_scenario]}
                type="select"
                label="Simulation Scenario"
                options={@dialysis_scenarios}
                required
              />
            <% end %>

            <:actions>
              <.button phx-disable-with="Saving...">Save Changes</.button>
            </:actions>
          </.simple_form>
        </div>
      </div>
    </div>
    """
  end
end
