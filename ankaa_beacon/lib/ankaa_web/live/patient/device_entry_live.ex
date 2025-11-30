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
    patient = socket.assigns.current_user.patient
    existing_devices = Devices.list_devices_for_patient(patient.id)

    if Enum.count(existing_devices) >= 2 do
      {:noreply,
       put_flash(socket, :error, "You have reached the maximum of two registered devices.")}
    else
      attrs = Map.put(device_params, "patient_id", patient.id)

      case Devices.create_device(attrs) do
        {:ok, _device} ->
          {:noreply,
           socket
           |> put_flash(:info, "Device added successfully.")
           |> push_navigate(to: ~p"/patient/devices")}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, form: to_form(changeset))}
      end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto py-8">
      <.link
        navigate={~p"/patient/devices"}
        class="text-sm font-semibold text-indigo-600 mb-4 inline-block"
      >
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

        <div class="px-4 sm:px-6 pt-2">
          <div class="rounded-md bg-yellow-50 p-4 border border-yellow-200">
            <div class="flex">
              <div class="shrink-0">
                <svg
                  class="h-5 w-5 text-yellow-400"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path
                    fill-rule="evenodd"
                    d="M8.485 2.495c.673-1.167 2.357-1.167 3.03 0l6.28 10.875c.673 1.167-.17 2.625-1.516 2.625H3.72c-1.347 0-2.189-1.458-1.515-2.625L8.485 2.495zM10 5a.75.75 0 01.75.75v3.5a.75.75 0 01-1.5 0v-3.5A.75.75 0 0110 5zm0 9a1 1 0 100-2 1 1 0 000 2z"
                    clip-rule="evenodd"
                  />
                </svg>
              </div>
              <div class="ml-3">
                <h3 class="text-sm font-medium text-yellow-800">Dashboard Limitation</h3>
                <div class="mt-2 text-sm text-yellow-700">
                  <p>
                    Please note: The monitoring dashboard is currently optimized to display
                    <strong>one Blood Pressure Monitor</strong>
                    and <strong>one Dialysis Machine</strong>.
                  </p>
                  <p class="mt-1">
                    It is strongly suggested that you add exactly one of each. Multiple devices of the same type are not yet handled in the UI.
                  </p>
                </div>
              </div>
            </div>
          </div>
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
