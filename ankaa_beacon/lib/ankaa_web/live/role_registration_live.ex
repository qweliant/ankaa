defmodule AnkaaWeb.RoleRegistrationLive do
  use AnkaaWeb, :live_view

  import AnkaaWeb.UserAuth

  alias Ankaa.Accounts
  alias Ankaa.Patients
  alias Ankaa.Patients.Patient
  alias Ecto.Multi
  alias Ankaa.Repo

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

  @impl true
  def mount(_params, _session, socket) do
    # Redirects if user has already completed this step
    if socket.assigns.current_user.role || socket.assigns.current_user.patient do
      {:ok,
       push_navigate(socket,
         to: signed_in_path(%Plug.Conn{assigns: %{current_user: socket.assigns.current_user}})
       )}
    else
      # The form for the final step is now for a Patient changeset
      patient_form = to_form(Patient.changeset(%Patient{}, %{}))

      {:ok,
       assign(socket,
         step: :role_selection,
         selected_role: nil,
         roles: @roles,
         token_form: to_form(%{"token" => ""}, as: :token),
         show_final_form: false,
         patient_form: patient_form,
         name_form: to_form(Accounts.User.name_changeset(socket.assigns.current_user, %{}))
       )}
    end
  end

  @impl true
  def handle_event("select_role", %{"role" => role}, socket) do
    {:noreply, assign(socket, step: :token_input, selected_role: role)}
  end

  @impl true
  def handle_event("back_to_roles", _params, socket) do
    {:noreply,
     assign(socket,
       step: :role_selection,
       selected_role: nil,
       show_final_form: false,
       token_form: to_form(%{"token" => ""}, as: :token),
       patient_form: to_form(Patient.changeset(%Patient{}, %{})),
       provider_name_form: to_form(Accounts.User.name_changeset(socket.assigns.current_user, %{}))
     )}
  end

  @impl true
  def handle_event("save_role", %{"token" => %{"token" => token}}, socket) do
    role = socket.assigns.selected_role

    if role == "patient" and token == "patient" do
      {:noreply, assign(socket, show_final_form: true)}
    else
      is_valid_token = token == role

      if is_valid_token do
        {:noreply, assign(socket, show_final_form: true)}
      else
        {:noreply, put_flash(socket, :error, "Invalid token for selected role.")}
      end
    end
  end

  @impl true
  def handle_event("save_name", %{"user" => name_params}, socket) do
    user = socket.assigns.current_user
    role = socket.assigns.selected_role

    result =
      Multi.new()
      |> Multi.run(:user_role, fn _repo, _changes ->
        Accounts.assign_role(user, role)
      end)
      |> Multi.run(:user_name, fn _repo, %{user_role: updated_user} ->
        Accounts.update_user_name(updated_user, name_params)
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
  def handle_event("save_patient_profile", %{"patient" => patient_params}, socket) do
    user = socket.assigns.current_user

    case Patients.create_patient(patient_params, user) do
      {:ok, _patient} ->
        fresh_user = Accounts.get_user!(user.id)
        redirect_to_dashboard(socket, fresh_user)

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, patient_form: to_form(changeset))}
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
                type="button"
                phx-click="select_role"
                phx-value-role={role_id}
                class={
                  [
                    "relative flex flex-col items-start p-5 w-full text-left rounded-xl border-2 transition-all duration-200 ease-in-out shadow-sm group",
                    # Conditional Styling for Active vs Inactive state
                    if role_id == @selected_role do
                      "border-purple-600 bg-purple-50 ring-1 ring-purple-600 shadow-purple-100"
                    else
                      "border-stone-200 bg-white hover:border-purple-300 hover:bg-stone-50 hover:shadow-md"
                    end
                  ]
                }
              >
                <div class="flex items-center w-full mb-2">
                  <div class={[
                    "p-2 rounded-lg shrink-0 mr-3 transition-colors",
                    if role_id == @selected_role do
                      "bg-purple-600 text-white"
                    else
                      "bg-stone-100 text-stone-500 group-hover:bg-purple-100 group-hover:text-purple-600"
                    end
                  ]}>
                    <.icon name={role_icon(role_id)} class="w-6 h-6" />
                  </div>
                  <div class={[
                    "font-bold text-lg",
                    if role_id == @selected_role do
                      "text-purple-900"
                    else
                      "text-stone-900"
                    end
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
                  if role_id == @selected_role do
                    "text-purple-800"
                  else
                    "text-stone-500"
                  end
                ]}>
                  {description}
                </p>
              </button>
            <% end %>
          </div>
        <% :token_input -> %>
          <div class="mt-8">
            <button phx-click="back_to_roles" class="mb-4 ...">
              <.icon name="hero-arrow-left-mini" class="w-5 h-5" /> Back to Role Selection
            </button>

            <%= if !@show_final_form do %>
              <.simple_form for={@token_form} id="token_form" phx-submit="save_role">
                <.input
                  field={@token_form[:token]}
                  type="text"
                  label={token_label(@selected_role)}
                  required
                />
                <:actions>
                  <.button phx-disable-with="Verifying..." class="w-full">Continue</.button>
                </:actions>
              </.simple_form>
            <% else %>
              <%= if @selected_role == "patient" do %>
                <.header class="text-center mt-8">Create Your Patient Profile</.header>
                <.simple_form for={@patient_form} id="patient_form" phx-submit="save_patient_profile">
                  <.input field={@patient_form[:name]} type="text" label="Full Name" required />
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
                <.header class="text-center mt-8">Enter Your Name</.header>
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

  defp token_label(role) do
    case role do
      "patient" -> "Patient Registration Code"
      "doctor" -> "Medical License Number"
      "nurse" -> "Nursing License Number"
      "caresupport" -> "Invitation Code"
      "clinic_technician" -> "Clinic Technician ID"
      "community_coordinator" -> "Community Admin Code"
      "social_worker" -> "Professional License Number"
      _ -> "Registration Code"
    end
  end

  defp timezone_options do
    Tzdata.zone_list()
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
end
