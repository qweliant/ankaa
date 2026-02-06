defmodule AnkaaWeb.PortalLive.Index do
  use AnkaaWeb, :live_view

  alias Ankaa.Patients
  alias Ankaa.Communities
  alias Ankaa.Accounts.NPI

  @create_patient_types %{
    name: :string,
    role: :string,
    relationship: :string
  }

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    communities = Communities.list_organizations_for_user(user)
    my_patient_profile = Patients.get_patient_by_user_id(user.id)

    {:ok, care_networks} = Patients.list_patients_for_user(user)

    org_changeset = Communities.change_organization(%Ankaa.Community.Organization{})
    form_changeset = create_patient_form_changeset(%{})

    {:ok,
     assign(socket,
       page_title: "My Portal",
       communities: communities,
       care_networks: care_networks,
       my_patient_profile: my_patient_profile,
       show_create_org_modal: false,
       show_create_patient_modal: false,
       org_form: to_form(org_changeset),
       patient_form: to_form(form_changeset, as: "patient"),
       # :role_selection | :details
       modal_step: :role_selection,
       selected_role: nil,
       npi_verifying: false,
       # Stores verified doctor info
       npi_data: nil,

       # Define the available roles for the hub (similar to your registration list)
       hub_roles: [
         {"patient", "Patient (Self)", "I am creating this for myself.", "hero-heart"},
         {"caresupport", "Family/Caregiver", "I am caring for a loved one.", "hero-users"},
         {"doctor", "Doctor", "I am a provider overseeing this patient.", "hero-user-plus"},
         {"nurse", "Nurse", "I am a nurse managing care.", "hero-clipboard-document-check"},
         {"tech", "Clinic Technician", "I work at a dialysis clinic and oversee patient data.",
          "hero-computer-desktop"},
         {"social_worker", "Social Worker", "I provide support resources.", "hero-lifebuoy"}
       ]
     )}
  end

  @impl true
  def handle_event("select_hub_role", %{"role" => role}, socket) do
    relationship_default = if role == "patient", do: "Self", else: ""
    current_npi = socket.assigns.current_user.npi_number

    changeset =
      create_patient_form_changeset(%{
        "role" => role,
        "relationship" => relationship_default,
        "npi" => current_npi
      })

    {:noreply,
     assign(socket,
       modal_step: :details,
       selected_role: role,
       patient_form: to_form(changeset, as: "patient")
     )}
  end

  @impl true
  def handle_event("toggle_create_org", _params, socket) do
    {:noreply, assign(socket, show_create_org_modal: !socket.assigns.show_create_org_modal)}
  end

  @impl true
  def handle_event("toggle_create_patient", _params, socket) do
    {:noreply,
     assign(socket, show_create_patient_modal: !socket.assigns.show_create_patient_modal)}
  end

  @impl true
  def handle_event("create_community", %{"organization" => org_params}, socket) do
    user = socket.assigns.current_user

    case Communities.create_organization_with_defaults(user, org_params) do
      {:ok, %{org: _org}} ->
        updated_list = Communities.list_organizations_for_user(user)

        socket =
          socket
          |> put_flash(:info, "Community created successfully!")
          |> assign(communities: updated_list, show_create_org_modal: false)

        {:noreply, socket}

      {:error, failed_step, failed_value, _changes} ->
        {:noreply, handle_transaction_error(socket, failed_step, failed_value)}
    end
  end

  @impl true
  def handle_event("create_patient", %{"patient" => patient_params}, socket) do
    user = socket.assigns.current_user
    case Patients.create_patient_hub(user, patient_params) do
      {:ok, %{patient: _patient}} ->
        {:ok, updated_networks} = Patients.list_patients_for_user(user)

        socket =
          socket
          |> put_flash(:info, "Care Network created successfully!")
          |> assign(care_networks: updated_networks, show_create_patient_modal: false)

        {:noreply, socket}

      {:error, failed_step, failed_value, _changes} ->
        {:noreply, handle_transaction_error(socket, failed_step, failed_value)}
    end
  end

  @impl true
  def handle_event("validate_patient", %{"patient" => params}, socket) do
    changeset =
      create_patient_form_changeset(params)
      |> Map.put(:action, :validate)

    npi_input = params["npi"]

    socket =
      if npi_input && String.length(npi_input) == 10 &&
           npi_input != socket.assigns.current_user.npi_number do
        case NPI.lookup(npi_input) do
          {:ok, data} ->
            assign(socket, npi_data: data)
            |> put_flash(:info, "Verified: #{data.first_name} #{data.last_name}")

          _ ->
            assign(socket, npi_data: nil)
        end
      else
        socket
      end

    {:noreply, assign(socket, patient_form: to_form(changeset, as: "patient"))}
  end

  def handle_event("back_to_role_selection", _, socket) do
    {:noreply, assign(socket, modal_step: :role_selection, selected_role: nil)}
  end

  defp handle_transaction_error(socket, failed_step, failed_value) do
    error_msg =
      case failed_value do
        %Ecto.Changeset{} = changeset ->
          errors =
            Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
              Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
                opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
              end)
            end)

          "Validation failed at #{failed_step}: #{inspect(errors)}"

        _ ->
          "Failed at step: #{failed_step}"
      end

    put_flash(socket, :error, error_msg)
  end

  defp create_patient_form_changeset(params) do
    {%{}, @create_patient_types}
    |> Ecto.Changeset.cast(params, Map.keys(@create_patient_types))
    |> Ecto.Changeset.validate_required([:name, :role, :relationship])
  end

  defp role_label(patient) do
    case List.first(patient.memberships) do
      %{role: role} -> format_role(role)
      _ -> "Caregiver View"
    end
  end

  defp format_role(role) when role in [:doctor, :nurse, :tech, :clinic_technician], do: "Clinical View"
  defp format_role(:social_worker), do: "Caseworker View"
  defp format_role(:caresupport), do: "Family View"
  defp format_role(:patient), do: "Self View" # Should typically fall into "My Health" block, but good fallback
  defp format_role(_), do: "Careprovider View"
end
