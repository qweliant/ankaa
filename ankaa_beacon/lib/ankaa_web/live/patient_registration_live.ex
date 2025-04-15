defmodule AnkaaWeb.PatientRegistrationLive do
  use AnkaaWeb, :live_view
  alias Ankaa.Patients
  alias Ankaa.Patients.Patient

  def mount(%{"token" => token}, _session, socket) do
    # For now, we'll just check if the token is "patient" (hardcoded)
    # In the future, this should verify against a proper invite system
    if token == "patient" do
      {:ok,
       socket
       |> assign(:page_title, "Register as Patient")
       |> assign(:changeset, Patient.changeset(%Patient{}, %{}))}
    else
      {:ok,
       socket
       |> put_flash(:error, "Invalid registration token")
       |> redirect(to: ~p"/")}
    end
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
        {:noreply,
         socket
         |> put_flash(:info, "Patient registration successful!")
         |> redirect(to: ~p"/dashboard")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-50">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="max-w-md mx-auto">
          <h1 class="text-2xl font-bold text-slate-900 mb-6">Register as Patient</h1>

          <.form
            for={@changeset}
            id="patient-registration-form"
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
              <.button phx-disable-with="Registering..." class="w-full">
                Register as Patient
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
