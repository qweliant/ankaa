defmodule AnkaaWeb.UserRegistrationLive do
  use AnkaaWeb, :live_view

  alias Ankaa.Accounts
  alias Ankaa.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Register for an account
        <:subtitle>
          Already registered?
          <.link navigate={~p"/users/login"} class="font-semibold text-brand hover:underline">
            Log in
          </.link>
          to your account now.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
      >
        <.error :if={@check_errors}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <:actions>
          <.button phx-disable-with="Creating account..." class="w-full">Create an account</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(%{"invite_token" => token}, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      # Store the token for later
      |> assign(invite_token: token)
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      # Ensure invite_token is nil
      |> assign(invite_token: nil)
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        # Log the new user in by putting their token in the session
        token = Accounts.generate_user_session_token(user)
        socket = Phoenix.LiveView.put_session(socket, :user_token, token)
        # Check if we have an invite token waiting
        case socket.assigns.invite_token do
          nil ->
            # No invite token, normal registration flow
            {:noreply,
             socket
             |> put_flash(:info, "Account created. Please check your email to confirm.")
             |> push_navigate(to: ~p"/")}

          invite_token ->
            # Found an invite token, redirect to the accept page
            {:noreply,
             socket
             |> put_flash(:info, "Account created. Now accepting your invitation...")
             |> push_navigate(to: ~p"/invites/accept?token=#{invite_token}")}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
