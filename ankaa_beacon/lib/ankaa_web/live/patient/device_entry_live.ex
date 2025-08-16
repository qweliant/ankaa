defmodule AnkaaWeb.DeviceEntryLive do
  use AnkaaWeb, :patient_layout

  alias Ankaa.Devices
  alias Ankaa.Patients.Device
  alias Phoenix.HTML.Form

  # Define the available scenarios for our dropdowns
  @bp_scenarios [
    Normal: "Normal",
    "High Systolic": "HighSystolic",
    "Low Diastolic": "LowDiastolic",
    "Irregular Heartbeat": "IrregularHeartbeat"
  ]
  @dialysis_scenarios [
    Normal: "Normal",
    "High Venous Pressure": "HighVP",
    "Low Blood Flow": "LowBFR"
  ]

  @impl true
  def mount(_params, _session, socket) do
    changeset = Device.changeset(%Device{}, %{})

    socket =
      socket
      |> assign(:form, to_form(changeset))
      |> assign(:current_path, "/patient/devices/new")
      |> assign(:bp_scenarios, @bp_scenarios)
      |> assign(:dialysis_scenarios, @dialysis_scenarios)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"device" => device_params}, socket) do
    # This event is triggered on form changes to provide live validation feedback
    changeset = Device.changeset(%Device{}, device_params)
    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"device" => device_params}, socket) do
    patient_id = socket.assigns.current_user.patient.id
    attrs = Map.put(device_params, "patient_id", patient_id)

    case Devices.create_device(attrs) do
      {:ok, device} ->
        {:noreply,
         socket
         |> put_flash(:info, "#{device.type} device added successfully.")
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
            Add a Simulated Device
          </h3>
          <p class="mt-1 max-w-2xl text-sm text-gray-500">
            Choose a device type and a simulation scenario to add to your account. This will create a unique virtual device for you.
          </p>
        </div>
        <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
          <.simple_form for={@form} phx-submit="save" phx-change="validate">
            <.input
              field={@form[:type]}
              type="select"
              label="Device Type"
              prompt="Choose a type..."
              options={[
                {"Blood Pressure Monitor", "blood_pressure"},
                {"Dialysis Machine", "dialysis"}
              ]}
              required
            />

            <%= if Form.input_value(@form, :type) == "blood_pressure" do %>
              <.input
                field={@form[:simulation_scenario]}
                type="select"
                label="Simulation Scenario"
                prompt="Choose a behavior..."
                options={@bp_scenarios}
                required
              />
            <% end %>

            <%= if Form.input_value(@form, :type) == "dialysis" do %>
              <.input
                field={@form[:simulation_scenario]}
                type="select"
                label="Simulation Scenario"
                prompt="Choose a behavior..."
                options={@dialysis_scenarios}
                required
              />
            <% end %>

            <:actions>
              <.button phx-disable-with="Adding...">Add Device</.button>
            </:actions>
          </.simple_form>
        </div>
      </div>
    </div>
    """
  end
end
