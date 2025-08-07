defmodule AnkaaWeb.PatientEntryLive do
  use AnkaaWeb, :live_view

  import AnkaaWeb.UserAuth

  alias Ankaa.Patients
  alias Ankaa.Patients.Patient
  alias Ankaa.Accounts
  alias Ankaa.Repo

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Patient Device Registration")
     |> assign(:changeset, Patient.changeset(%Patient{}, %{}))}
  end

  def handle_event("validate", %{"patient" => patient_params}, socket) do
    changeset =
      %Patient{}
      |> Patient.changeset(patient_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"patient" => patient_params}, socket) do
    case Patients.create_patient(patient_params, socket.assigns.current_user) do
      {:ok, _patient} ->
        # Assign patient role to user
        {:ok, _user} = Accounts.assign_role(socket.assigns.current_user, "patient")

        # Reload user and preload patient association
        user =
          Repo.get(Accounts.User, socket.assigns.current_user.id)
          |> Repo.preload(:patient)

        {:noreply,
         redirect(socket,
           to: signed_in_path(%Plug.Conn{assigns: %{current_user: user}})
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-50">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="max-w-md mx-auto">
          <h1 class="text-2xl font-bold text-slate-900 mb-6">Patient Device Registration</h1>

          <.form
            for={@changeset}
            id="patient-entry-form"
            phx-change="validate"
            phx-submit="save"
            class="space-y-6"
          >
            <div>
              <.input
                field={@changeset[:name]}
                type="text"
                label="Full Name"
                required
              />
            </div>

            <div>
              <.input
                field={@changeset[:date_of_birth]}
                type="date"
                label="Date of Birth"
                required
              />
            </div>

            <div>
              <.input
                field={@changeset[:timezone]}
                type="select"
                label="Timezone"
                options={timezone_options()}
                required
              />
            </div>

            <div>
              <.input
                field={@changeset[:device_id]}
                type="text"
                label="Dialysis Device ID"
                required
              />
            </div>

            <div>
              <.input
                field={@changeset[:bp_device_id]}
                type="text"
                label="Blood Pressure Device ID"
                required
              />
            </div>

            <div>
              <.button phx-disable-with="Registering..." class="w-full">
                Complete Registration
              </.button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  defp timezone_options do
    Tzdata.zone_list()
    |> Enum.map(&{&1, &1})
  end
end
