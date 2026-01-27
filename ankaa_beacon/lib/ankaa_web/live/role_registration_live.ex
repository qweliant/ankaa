defmodule AnkaaWeb.RoleRegistrationLive do
  use AnkaaWeb, :live_view

  import AnkaaWeb.UserAuth

  alias Ankaa.Accounts
  alias Ankaa.Patients
  alias Ankaa.Patients.Patient
  alias Ecto.Multi
  alias Ankaa.Repo
  alias Ankaa.Accounts.NPI

  @roles [
    {"patient", "Patient", "I am receiving home hemodialysis treatment"},
    {"doctor", "Doctor", "I am a healthcare provider overseeing patients"},
    {"nurse", "Nurse", "I am a nurse supporting patients"},
    {"caresupport", "Care support", "I help take care of a patient"},
    {"clinic_technician", "Clinic Technician",
     "I work at a dialysis clinic and oversee patient data."},
    {"community_coordinator", "Community Coordinator",
     "I manage a community of dialysis patients."},
    {"social_worker", "Social Worker",
     "I provide psychosocial support and non-medical resources."}
  ]

  @npi_roles ["doctor", "nurse", "social_worker"]

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_user.role || socket.assigns.current_user.patient do
      {:ok,
       push_navigate(socket,
         to: signed_in_path(%Plug.Conn{assigns: %{current_user: socket.assigns.current_user}})
       )}
    else
      user_cs = Accounts.User.name_changeset(socket.assigns.current_user, %{})
      patient_cs = Patient.changeset(%Patient{}, %{})

      {:ok,
       assign(socket,
         step: :role_selection,
         selected_role: nil,
         roles: @roles,
         npi_roles: @npi_roles,
         token_form: to_form(%{"token" => ""}, as: :token),
         show_final_form: false,
         patient_form: to_form(patient_cs),
         name_form: to_form(user_cs),
         npi_data: nil
       )}
    end
  end

  @impl true
  def handle_event("select_role", %{"role" => role}, socket) do
    {:noreply, assign(socket, step: :token_input, selected_role: role)}
  end

  @impl true
  def handle_event("back_to_roles", _params, socket) do
    user_cs = Accounts.User.name_changeset(socket.assigns.current_user, %{})
    patient_cs = Patient.changeset(%Patient{}, %{})

    {:noreply,
     assign(socket,
       step: :role_selection,
       selected_role: nil,
       show_final_form: false,
       token_form: to_form(%{"token" => ""}, as: :token),
       patient_form: to_form(patient_cs),
       name_form: to_form(user_cs),
       npi_roles: @npi_roles
     )}
  end

  @impl true
  def handle_event("save_role", %{"token" => %{"token" => token}}, socket) do
    role = socket.assigns.selected_role
    # Normalize token: trim whitespace and lowercase it for easier matching
    normalized_token = token |> String.trim() |> String.downcase()

    cond do
      role == "patient" ->
        {:noreply, assign(socket, show_final_form: true)}

      # If they typed the "Magic Word" (the role name itself), skip NPI lookup
      normalized_token == role ->
        {:noreply, assign(socket, show_final_form: true)}

      # Otherwise, try NPI lookup for medical roles
      role in @npi_roles ->
        perform_npi_lookup(socket, token)

      true ->
        {:noreply, put_flash(socket, :error, "Invalid Code. Please check and try again.")}
    end
  end

  @impl true
  def handle_event("save_name", %{"user" => name_params}, socket) do
    user = socket.assigns.current_user
    role = socket.assigns.selected_role

    final_params =
      if socket.assigns.npi_data do
        name_params
        |> Map.put("npi_number", socket.assigns.npi_data.number)
        |> Map.put("practice_state", socket.assigns.npi_data.practice_state)
      else
        name_params
      end

    result =
      Multi.new()
      |> Multi.run(:user_role, fn _repo, _changes ->
        Accounts.assign_role(user, role)
      end)
      |> Multi.run(:user_name, fn _repo, %{user_role: updated_user} ->
        Accounts.update_user_profile(updated_user, final_params)
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{user_name: final_user}} ->
        redirect_to_dashboard(socket, final_user)

      {:error, :user_name, changeset, _changes} ->
        {:noreply, assign(socket, name_form: to_form(changeset))}

      {:error, :user_role, _reason, _changes} ->
        {:noreply, put_flash(socket, :error, "System error assigning role.")}
    end
  end

  @impl true
  def handle_event(
        "save_patient_profile",
        %{"patient" => patient_params, "user" => user_params},
        socket
      ) do
    user = socket.assigns.current_user

    case Accounts.update_user_name(user, user_params) do
      {:ok, updated_user} ->
        full_name = "#{updated_user.first_name} #{updated_user.last_name}"
        final_patient_params = Map.put(patient_params, "name", full_name)

        case Patients.create_patient(final_patient_params, updated_user) do
          {:ok, _patient} ->
            fresh_user = Accounts.get_user!(updated_user.id)
            redirect_to_dashboard(socket, fresh_user)

          {:error, changeset} ->
            {:noreply, assign(socket, patient_form: to_form(changeset))}
        end

      {:error, changeset} ->
        {:noreply, assign(socket, name_form: to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-md">
      <.header class="text-center">
        Complete Your Registration
        <:subtitle>Let us know your role to continue.</:subtitle>
      </.header>

      <%= case @step do %>
        <% :role_selection -> %>
          <div class="mt-8 grid grid-cols-1 gap-4 sm:grid-cols-2">
            <%= for {role_id, label, description} <- @roles do %>
              <button
                phx-click="select_role"
                phx-value-role={role_id}
                class={[
                  "relative flex flex-col items-start p-5 w-full text-left rounded-xl border-2 transition-all duration-200 ease-in-out shadow-sm group",
                  if(role_id == @selected_role,
                    do: "border-purple-600 bg-purple-50 ring-1 ring-purple-600 shadow-purple-100",
                    else:
                      "border-stone-200 bg-white hover:border-purple-300 hover:bg-stone-50 hover:shadow-md"
                  )
                ]}
              >
                <div class="flex items-center w-full mb-2">
                  <div class={[
                    "p-2 rounded-lg shrink-0 mr-3 transition-colors",
                    if(role_id == @selected_role,
                      do: "bg-purple-600 text-white",
                      else:
                        "bg-stone-100 text-stone-500 group-hover:bg-purple-100 group-hover:text-purple-600"
                    )
                  ]}>
                    <.icon name={role_icon(role_id)} class="w-6 h-6" />
                  </div>
                  <div class={[
                    "font-bold text-lg",
                    if(role_id == @selected_role, do: "text-purple-900", else: "text-stone-900")
                  ]}>
                    {label}
                  </div>
                  <%= if role_id == @selected_role do %>
                    <div class="ml-auto text-purple-600">
                      <.icon name="hero-check-circle-solid" class="w-6 h-6" />
                    </div>
                  <% end %>
                </div>
                <p class={[
                  "text-sm leading-relaxed",
                  if(role_id == @selected_role, do: "text-purple-800", else: "text-stone-500")
                ]}>
                  {description}
                </p>
              </button>
            <% end %>
          </div>
        <% :token_input -> %>
          <div class="mt-8">
            <button
              phx-click="back_to_roles"
              class="mb-4 text-sm text-stone-600 hover:text-purple-600 flex items-center"
            >
              <.icon name="hero-arrow-left-mini" class="w-5 h-5 mr-1" /> Back to Role Selection
            </button>

            <%= if !@show_final_form do %>
              <.simple_form for={@token_form} id="token_form" phx-submit="save_role">
                <.input
                  field={@token_form[:token]}
                  type="text"
                  label={token_label(@selected_role)}
                  placeholder={token_placeholder(@selected_role)}
                  required
                />
                <p class="text-xs text-slate-500 mt-1">
                  Beta Access: You can type
                  <span class="font-mono bg-slate-100 px-1 rounded text-purple-700">
                    {@selected_role}
                  </span>
                  to skip verification.
                </p>

                <:actions>
                  <.button phx-disable-with="Verifying..." class="w-full">
                    {if @selected_role in @npi_roles, do: "Verify NPI & Continue", else: "Continue"}
                  </.button>
                </:actions>
              </.simple_form>
            <% else %>
              <%= if @selected_role == "patient" do %>
                <.header class="text-center mt-8">Create Your Patient Profile</.header>
                <.simple_form for={@patient_form} id="patient_form" phx-submit="save_patient_profile">
                  <div class="grid grid-cols-2 gap-4">
                    <.input
                      field={@name_form[:first_name]}
                      name="user[first_name]"
                      type="text"
                      label="First Name"
                      required
                      value={@name_form.params["first_name"] || @name_form.data.first_name}
                      errors={@name_form.errors[:first_name]}
                    />
                    <.input
                      field={@name_form[:last_name]}
                      name="user[last_name]"
                      type="text"
                      label="Last Name"
                      required
                      value={@name_form.params["last_name"] || @name_form.data.last_name}
                      errors={@name_form.errors[:last_name]}
                    />
                  </div>

                  <.input
                    field={@patient_form[:date_of_birth]}
                    type="date"
                    label="Date of Birth"
                    required
                  />
                  <.input
                    field={@patient_form[:timezone]}
                    type="select"
                    label="Timezone"
                    options={timezone_options()}
                    required
                  />
                  <:actions>
                    <.button phx-disable-with="Saving..." class="w-full">
                      Complete Registration
                    </.button>
                  </:actions>
                </.simple_form>
              <% else %>
                <.header class="text-center mt-8">Confirm Your Details</.header>
                <.simple_form for={@name_form} id="name_form" phx-submit="save_name">
                  <.input field={@name_form[:first_name]} type="text" label="First Name" required />
                  <.input field={@name_form[:last_name]} type="text" label="Last Name" required />
                  <:actions>
                    <.button phx-disable-with="Saving..." class="w-full">
                      Complete Registration
                    </.button>
                  </:actions>
                </.simple_form>
              <% end %>
            <% end %>
          </div>
      <% end %>
    </div>
    """
  end

  # Updated to be more instructive for the Beta
  defp token_label(role) do
    case role do
      "doctor" -> "Enter NPI Number"
      "nurse" -> "Enter NPI or License Number"
      "social_worker" -> "Enter NPI or License Number"
      "patient" -> "Registration Code (Optional)"
      "clinic_technician" -> "Enter Clinic Access Code"
      "community_coordinator" -> "Enter Community Access Code"
      _ -> "Invitation Code"
    end
  end

  # Added placeholder to reinforce the "magic word" option
  defp token_placeholder(role) do
    "Enter code or type '#{role}'"
  end

  defp timezone_options do
    TzExtra.time_zone_ids()
    |> Enum.map(&{&1, &1})
  end

  defp redirect_to_dashboard(socket, user) do
    conn = %Plug.Conn{assigns: %{current_user: user}}
    {:noreply, push_navigate(socket, to: signed_in_path(conn))}
  end

  defp role_icon(role) do
    case role do
      "patient" -> "hero-heart"
      "doctor" -> "hero-user-plus"
      "nurse" -> "hero-clipboard-document-check"
      "caresupport" -> "hero-users"
      "clinic_technician" -> "hero-computer-desktop"
      "community_coordinator" -> "hero-chat-bubble-left-right"
      "social_worker" -> "hero-lifebuoy"
      _ -> "hero-user"
    end
  end

  defp perform_npi_lookup(socket, npi_number) do
    # Basic format check (NPI is 10 digits)
    if String.match?(npi_number, ~r/^\d{10}$/) do
      case NPI.lookup(npi_number) do
        {:ok, data} ->
          # PRE-FILL THE NAME FORM
          user = socket.assigns.current_user

          prefilled_params = %{
            "first_name" => data.first_name,
            "last_name" => data.last_name
          }

          changeset = Accounts.User.name_changeset(user, prefilled_params)

          socket =
            socket
            |> put_flash(
              :info,
              "Verified: #{data.first_name} #{data.last_name} - #{data.taxonomy_desc}"
            )
            |> assign(name_form: to_form(changeset))
            |> assign(show_final_form: true)
            # Ensure we save the NPI data to state
            |> assign(npi_data: data)

          {:noreply, socket}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "NPI Number not found in registry.")}
      end
    else
      # Fallback for the "Magic Word" bypass (e.g. typing "doctor")
      if npi_number == socket.assigns.selected_role do
        {:noreply, assign(socket, show_final_form: true)}
      else
        {:noreply, put_flash(socket, :error, "Invalid NPI Format (Must be 10 digits).")}
      end
    end
  end
end
