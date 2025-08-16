defmodule AnkaaWeb.RoleRegistrationLive do
  use AnkaaWeb, :live_view
  # Added for consistency, in case of future alerts
  use AnkaaWeb, :alert_handling

  import AnkaaWeb.UserAuth

  alias Ankaa.Accounts
  alias Ankaa.Patients
  alias Ankaa.Patients.Patient

  @roles [
    {"patient", "Patient", "I am receiving home hemodialysis treatment"},
    {"doctor", "Doctor", "I am a healthcare provider overseeing patients"},
    {"nurse", "Nurse", "I am a nurse supporting patients"},
    {"caresupport", "Care support", "I help take care of a patient"}
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
         provider_name_form:
           to_form(Accounts.User.name_changeset(socket.assigns.current_user, %{}))
       )}
    end
  end

  @impl true
  def handle_event("select_role", %{"role" => role}, socket) do
    {:noreply, assign(socket, step: :token_input, selected_role: role)}
  end

  @impl true
  def handle_event("back_to_roles", _params, socket) do
    {:noreply, assign(socket, step: :role_selection, selected_role: nil)}
  end

  @impl true
  def handle_event("save_role", %{"token" => %{"token" => token}}, socket) do
    user = socket.assigns.current_user
    role = socket.assigns.selected_role

    if role == "patient" and token == "patient" do
      {:noreply, assign(socket, show_final_form: true)}
    else
      is_valid_token = token == role

      if is_valid_token do
        case Accounts.assign_role(user, role) do
          {:ok, _updated_user} ->
            {:noreply, assign(socket, show_final_form: true)}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to assign role.")}
        end
      else
        {:noreply, put_flash(socket, :error, "Invalid token for selected role.")}
      end
    end
  end

  @impl true
  def handle_event("save_provider_name", %{"user" => name_params}, socket) do
    user = socket.assigns.current_user

    case Accounts.update_user_name(user, name_params) do
      {:ok, updated_user} ->
        redirect_to_dashboard(socket, updated_user)

      {:error, changeset} ->
        {:noreply, assign(socket, provider_name_form: to_form(changeset))}
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
          <div class="mt-8 space-y-4">
            <%= for {role_id, label, description} <- @roles do %>
              <button
                phx-click="select_role"
                phx-value-role={role_id}
                class={"w-full p-4 text-left ... #{if role_id == @selected_role, do: "border-amber-600", else: "border-stone-200"}"}
              >
                <div class="font-semibold text-stone-900"><%= label %></div>
                <div class="text-sm text-stone-600 mt-1"><%= description %></div>
              </button>
            <% end %>
          </div>

        <% :token_input -> %>
          <div class="mt-8">
            <button phx-click="back_to_roles" class="mb-4 ...">
              <.icon name="hero-arrow-left-mini" class="w-5 h-5" />
              Back to Role Selection
            </button>

            <%= if !@show_final_form do %>
              <.simple_form for={@token_form} id="token_form" phx-submit="save_role">
                <.input field={@token_form[:token]} type="text" label={token_label(@selected_role)} required />
                <:actions>
                  <.button phx-disable-with="Verifying..." class="w-full">Continue</.button>
                </:actions>
              </.simple_form>
            <% else %>
              <%= if @selected_role == "patient" do %>
                <.header class="text-center mt-8">Create Your Patient Profile</.header>
                <.simple_form for={@patient_form} id="patient_form" phx-submit="save_patient_profile">
                  <.input field={@patient_form[:name]} type="text" label="Full Name" required />
                  <.input field={@patient_form[:date_of_birth]} type="date" label="Date of Birth" required />
                  <.input
                    field={@patient_form[:timezone]}
                    type="select"
                    label="Timezone"
                    options={timezone_options()}
                    required
                  />
                  <:actions>
                    <.button phx-disable-with="Saving..." class="w-full">Complete Registration</.button>
                  </:actions>
                </.simple_form>
              <% else %>
                <.header class="text-center mt-8">Enter Your Name</.header>
                <.simple_form for={@provider_name_form} id="name_form" phx-submit="save_provider_name">
                  <.input field={@provider_name_form[:first_name]} type="text" label="First Name" required />
                  <.input field={@provider_name_form[:last_name]} type="text" label="Last Name" required />
                  <:actions>
                    <.button phx-disable-with="Saving..." class="w-full">Complete Registration</.button>
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
end
