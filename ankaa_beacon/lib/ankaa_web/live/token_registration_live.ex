defmodule AnkaaWeb.TokenRegistrationLive do
  use AnkaaWeb, :live_view
  import AnkaaWeb.UserAuth

  alias Ankaa.Accounts
  alias Ankaa.UserAuth
  alias Ankaa.Patients

  @roles [
    {"patient", "Patient", "I am receiving home hemodialysis treatment"},
    {"doctor", "Doctor", "I am a healthcare provider overseeing patients"},
    {"nurse", "Nurse", "I am a nurse supporting patients"},
    {"caresupport", "Care support", "I help take care of a patient"}
  ]

  def mount(_params, _session, socket) do
    if socket.assigns.current_user.role || socket.assigns.current_user.patient do
      {:ok,
       push_navigate(socket,
         to: signed_in_path(%Plug.Conn{assigns: %{current_user: socket.assigns.current_user}})
       )}
    else
      user = socket.assigns.current_user
      name_changeset = Accounts.User.name_changeset(user, %{})

      {:ok,
       assign(socket,
         step: :role_selection,
         selected_role: nil,
         roles: @roles,
         form: to_form(%{"token" => ""}, as: :user),
         show_name_form: false,
         name_form: to_form(name_changeset)
       )}
    end
  end

  def handle_event("select_role", %{"role" => role}, socket) do
    {:noreply, assign(socket, step: :token_input, selected_role: role)}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    {:noreply, assign(socket, form: to_form(user_params, as: :user))}
  end

  def handle_event("validate_name", %{"user" => user_params}, socket) do
    changeset =
      Ecto.Changeset.cast(socket.assigns.name_form.source, user_params, [
        :first_name,
        :last_name
      ])

    {:noreply, assign(socket, name_form: to_form(changeset))}
  end

  def handle_event("back_to_roles", _params, socket) do
    {:noreply, assign(socket, step: :role_selection, selected_role: nil)}
  end

  def handle_event("save", %{"user" => %{"token" => token}}, socket) do
    user = socket.assigns.current_user
    role = socket.assigns.selected_role
    is_valid_token = token == role || (role == "patient" && token == "patient")

    if is_valid_token do
      case Accounts.assign_role(user, role) do
        {:ok, _updated_user} ->
          {:noreply, assign(socket, show_name_form: true)}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to assign role. Please try again.")}
      end
    else
      {:noreply,
       socket
       |> put_flash(:error, "Invalid token for selected role. Please try again.")
       |> assign(form: to_form(%{"token" => ""}, as: :user))}
    end
  end

  def handle_event("save_name", %{"user" => name_params}, socket) do
    user = socket.assigns.current_user

    case Accounts.update_user_name(user, name_params) do
      {:ok, updated_user} ->
        if updated_user.role == "patient" do
          patient_attrs = %{name: "#{updated_user.first_name} #{updated_user.last_name}"}

          case Patients.create_patient(patient_attrs, updated_user) do
            {:ok, _patient} ->
              redirect_to_dashboard(socket, updated_user)

            {:error, _changeset} ->
              {:noreply,
               put_flash(socket, :error, "Failed to create patient profile. Please try again.")}
          end
        else
          redirect_to_dashboard(socket, updated_user)
        end

      {:error, changeset} ->
        {:noreply, assign(socket, name_form: to_form(changeset))}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-md">
      <.header class="text-center">
        Complete Your Registration
        <:subtitle>Let us know your role to continue with registration.</:subtitle>
      </.header>

      <%= case @step do %>
        <% :role_selection -> %>
          <div class="mt-8 space-y-4">
            <%= for {role_id, label, description} <- @roles do %>
              <button
                phx-click="select_role"
                phx-value-role={role_id}
                class={"w-full p-4 text-left bg-white hover:bg-stone-50 border-2 rounded-xl transition duration-200 #{if role_id == @selected_role, do: "border-amber-600", else: "border-stone-200"}"}
              >
                <div class="font-semibold text-stone-900"><%= label %></div>
                <div class="text-sm text-stone-600 mt-1"><%= description %></div>
              </button>
            <% end %>
          </div>

        <% :token_input -> %>
          <div class="mt-8">
            <button
              phx-click="back_to_roles"
              class="mb-4 text-stone-600 hover:text-stone-900 flex items-center gap-1"
            >
              <.icon name="hero-arrow-left-mini" class="w-5 h-5" />
              Back to Role Selection
            </button>

            <%= if !@show_name_form do %>
              <.simple_form
                for={@form}
                id="token_form"
                phx-submit="save"
                phx-change="validate"
              >
                <.input
                  field={@form[:token]}
                  type="text"
                  label={token_label(@selected_role)}
                  required
                />
                <:actions>
                  <.button phx-disable-with="Verifying..." class="w-full">
                    Continue
                  </.button>
                </:actions>
              </.simple_form>
            <% else %>
              <.header class="text-center mt-8">Enter Your Name</.header>
              <.simple_form
              for={@name_form}
              id="name_form"
              phx-submit="save_name"
              phx-change="validate_name"
              >
                <.input field={@name_form[:first_name]} type="text" label="First Name" required />
                <.input field={@name_form[:last_name]} type="text" label="Last Name" required />
                <:actions>
                  <.button phx-disable-with="Registering..." class="w-full">
                    Complete Registration
                  </.button>
                </:actions>
              </.simple_form>
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

  defp redirect_to_dashboard(socket, user) do
    conn = %Plug.Conn{assigns: %{current_user: user}}
    {:noreply, push_navigate(socket, to: signed_in_path(conn))}
  end
end
