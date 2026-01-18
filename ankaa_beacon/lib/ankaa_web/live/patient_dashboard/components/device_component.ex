defmodule AnkaaWeb.PatientDashboard.Components.DevicesComponent do
  @moduledoc """
  Manages patient devices: List, Add, Edit, Delete.
  Uses a modal for forms to keep the user on the dashboard.
  """
  use AnkaaWeb, :live_component

  alias Ankaa.Devices
  alias Ankaa.Patients.Device

  @bp_scenarios [
    {"Normal", "Normal"},
    {"High Systolic", "HighSystolic"},
    {"Low Diastolic", "LowDiastolic"},
    {"Irregular Heartbeat", "IrregularHeartbeat"}
  ]
  @dialysis_scenarios [
    {"Normal", "Normal"},
    {"High Venous Pressure", "HighVP"},
    {"Low Blood Flow", "LowBFR"}
  ]

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:bp_scenarios, @bp_scenarios)
     |> assign(:dialysis_scenarios, @dialysis_scenarios)
     |> assign(:show_modal, false)
     |> assign(:device_to_edit, nil)
     |> assign(:form, to_form(Devices.change_device(%Device{})))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    device = Devices.get_device!(id)
    {:ok, _} = Devices.delete_device(device)

    send(self(), :refresh_devices)

    {:noreply, put_flash(socket, :info, "Device removed successfully.")}
  end

  @impl true
  def handle_event("new_device", _, socket) do
    changeset = Devices.change_device(%Device{})

    {:noreply,
     assign(socket,
       show_modal: true,
       device_to_edit: nil,
       form: to_form(changeset)
     )}
  end

  @impl true
  def handle_event("edit_device", %{"id" => id}, socket) do
    device = Devices.get_device!(id)
    changeset = Devices.change_device(device)

    {:noreply,
     assign(socket,
       show_modal: true,
       device_to_edit: device,
       form: to_form(changeset)
     )}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, assign(socket, show_modal: false, device_to_edit: nil)}
  end

  @impl true
  def handle_event("save", %{"device" => device_params}, socket) do
    save_device(socket, socket.assigns.device_to_edit, device_params)
  end

  defp save_device(socket, nil, device_params) do
    if length(socket.assigns.devices) >= 2 do
      {:noreply, put_flash(socket, :error, "Maximum of 2 devices allowed.")}
    else
      params = Map.put(device_params, "patient_id", socket.assigns.patient.id)

      case Devices.create_device(params) do
        {:ok, _device} ->
          send(self(), :refresh_devices)

          {:noreply,
           socket
           |> assign(show_modal: false)
           |> put_flash(:info, "Device added successfully")}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, form: to_form(changeset))}
      end
    end
  end

  defp save_device(socket, device, device_params) do
    case Devices.update_device(device, device_params) do
      {:ok, _device} ->
        send(self(), :refresh_devices)

        {:noreply,
         socket
         |> assign(show_modal: false)
         |> put_flash(:info, "Device updated successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto space-y-6">
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-2xl font-bold text-slate-800">My Devices</h2>
          <p class="text-sm text-slate-500">Manage your simulators and connections</p>
        </div>
        <button
          phx-click="new_device"
          phx-target={@myself}
          class="bg-purple-600 text-white px-4 py-2 rounded-xl hover:bg-purple-700 transition font-bold text-sm shadow-md shadow-purple-200 flex items-center gap-2"
        >
          <.icon name="hero-plus" class="w-5 h-5" /> Add Device
        </button>
      </div>

      <div class="grid gap-4">
        <%= for device <- @devices do %>
          <div class="bg-white p-6 rounded-4xl border border-slate-100 shadow-sm flex items-center justify-between group hover:border-purple-100 transition-colors">
            <div class="flex items-center gap-4">
              <div class="h-12 w-12 rounded-full bg-purple-50 text-purple-600 flex items-center justify-center">
                <%= if device.type == "blood_pressure" do %>
                  <.icon name="hero-heart" class="w-6 h-6" />
                <% else %>
                  <.icon name="hero-cpu-chip" class="w-6 h-6" />
                <% end %>
              </div>
              <div>
                <h3 class="font-bold text-slate-800 text-lg">
                  {device.type |> String.replace("_", " ") |> String.capitalize()}
                </h3>
                <div class="flex items-center gap-2 mt-1">
                  <span class="text-xs font-bold uppercase tracking-wider text-slate-400">
                    Scenario
                  </span>
                  <span class="bg-slate-100 text-slate-600 px-2 py-0.5 rounded text-xs font-mono">
                    {device.simulation_scenario}
                  </span>
                </div>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <button
                phx-click="edit_device"
                phx-value-id={device.id}
                phx-target={@myself}
                class="p-2 text-slate-400 hover:text-purple-600 hover:bg-purple-50 rounded-lg transition"
              >
                <.icon name="hero-cog-6-tooth" class="w-6 h-6" />
              </button>
              <button
                phx-click="delete"
                phx-value-id={device.id}
                phx-target={@myself}
                data-confirm="Remove device?"
                class="p-2 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition"
              >
                <.icon name="hero-trash" class="w-6 h-6" />
              </button>
            </div>
          </div>
        <% end %>
        <%= if Enum.empty?(@devices) do %>
          <div class="text-center py-12 bg-slate-50 rounded-4xl border border-dashed border-slate-200">
            <p class="text-slate-500 font-medium">No devices connected</p>
          </div>
        <% end %>
      </div>

      <%= if @show_modal do %>
        <.modal id="device-modal" show on_cancel={JS.push("close_modal", target: @myself)}>
          <div class="p-6">
            <h3 class="text-lg font-bold text-slate-900 mb-4">
              {if @device_to_edit, do: "Edit Device", else: "Add Simulator"}
            </h3>
            <div role="status" aria-live="polite" class="ml-3 border-l-4 border-yellow-500 bg-yellow-50 p-4 rounded-md">
              <div class="flex items-start gap-3">
                <div class="text-yellow-600">
                  <.icon name="hero-exclamation-triangle" class="w-6 h-6" />
                </div>
                <div>
                  <h3 class="text-sm font-semibold text-yellow-800">Display limitation</h3>
                  <p class="mt-1 text-sm text-yellow-700">
                    The dashboard currently supports displaying up to
                    <strong>one Blood Pressure Monitor</strong> and
                    <strong>one Dialysis Machine</strong>. Adding multiple devices of the same type may not appear or behave correctly.
                  </p>
                  <p class="mt-2 text-xs text-yellow-600">
                    If you need to use more than one device of a type, manage them outside this UI or contact your administrator.
                  </p>
                </div>
              </div>
            </div>
            <.simple_form for={@form} phx-submit="save" phx-target={@myself}>
              <.input
                field={@form[:type]}
                type="select"
                label="Device Type"
                options={[
                  {"Blood Pressure Monitor", "blood_pressure"},
                  {"Dialysis Machine", "dialysis"}
                ]}
                disabled={@device_to_edit != nil}
              />

              <div class="mt-4">
                <%= if Phoenix.HTML.Form.input_value(@form, :type) == "blood_pressure" do %>
                  <.input
                    field={@form[:simulation_scenario]}
                    type="select"
                    label="Simulation Scenario"
                    options={@bp_scenarios}
                    prompt="Select behavior..."
                  />
                <% else %>
                  <.input
                    field={@form[:simulation_scenario]}
                    type="select"
                    label="Simulation Scenario"
                    options={@dialysis_scenarios}
                    prompt="Select behavior..."
                  />
                <% end %>
              </div>

              <:actions>
                <div class="flex justify-end gap-3 w-full">
                  <button
                    type="button"
                    phx-click="close_modal"
                    phx-target={@myself}
                    class="px-4 py-2 text-slate-600 font-bold hover:bg-slate-50 rounded-lg"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    class="px-6 py-2 bg-purple-600 text-white font-bold rounded-lg hover:bg-purple-700"
                  >
                    {if @device_to_edit, do: "Save Changes", else: "Add Device"}
                  </button>
                </div>
              </:actions>
            </.simple_form>
          </div>
        </.modal>
      <% end %>
    </div>
    """
  end
end
