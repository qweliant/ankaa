defmodule AnkaaWeb.DeviceEntryLive do
  use AnkaaWeb, :live_view
  import AnkaaWeb.UserAuth

  alias Ankaa.Patients
  alias Ankaa.Patients.Device

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Register Device")
     |> assign(:changeset, Device.changeset(%Device{}, %{}))}
  end

  def handle_event("validate", %{"device" => device_params}, socket) do
    changeset =
      %Device{}
      |> Device.changeset(device_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"device" => device_params}, socket) do
    user = socket.assigns.current_user
    patient = user.patient

    attrs = Map.put(device_params, "patient_id", patient.id)

    case Patients.Device.changeset(%Device{}, attrs) |> Patients.Repo.insert() do
      {:ok, _device} ->
        {:noreply, redirect(socket, to: ~p"/patient/dashboard")}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-50">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="max-w-md mx-auto">
          <h1 class="text-2xl font-bold text-slate-900 mb-6">Register Device</h1>

          <.form :let={f} for={@changeset} id="device-entry-form" phx-change="validate" phx-submit="save" class="space-y-6">
            <div>
              <.input field={f[:type]} type="text" label="Device Type (e.g. dialysis, bp)" required />
            </div>
            <div>
              <.input field={f[:model]} type="text" label="Model" />
            </div>
            <div>
              <.input field={f[:device_id]} type="text" label="Device ID" required />
            </div>
            <div>
              <.button phx-disable-with="Registering..." class="w-full">
                Register Device
              </.button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end
end
