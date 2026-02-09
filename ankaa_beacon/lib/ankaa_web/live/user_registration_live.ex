defmodule AnkaaWeb.UserRegistrationLive do
  use AnkaaWeb, :live_view

  alias Ankaa.Accounts
  alias Ankaa.Accounts.User

  @impl true
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

      <.simple_form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
        <.error :if={@check_errors}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <div class="grid grid-cols-2 gap-4">
          <.input field={@form[:first_name]} type="text" label="First Name" required />
          <.input field={@form[:last_name]} type="text" label="Last Name" required />
        </div>

        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />
        <div class="flex items-start gap-3 my-6 p-4 bg-slate-50 rounded-lg border border-slate-200">
          <div class="flex h-6 items-center">
            <.input
              field={@form[:terms_agreement]}
              type="checkbox"
              required
              class="h-4 w-4 rounded border-gray-300 text-purple-600 focus:ring-purple-600"
            />
          </div>
          <div class="text-sm leading-6">
            <label for={@form[:terms_agreement].id} class="font-medium text-gray-900">
              I agree to the <a
                href="https://app.termly.io/policy-viewer/policy.html?policyUUID=54a102a0-571e-47df-acc7-69e3004f55ef"
                target="_blank"
                class="font-bold text-purple-600 hover:text-purple-500 underline"
              >Terms of Service</a>, <a
                href="https://app.termly.io/policy-viewer/policy.html?policyUUID=be512ebe-9aa0-4146-9559-7b6f929fd240"
                target="_blank"
                class="font-bold text-purple-600 hover:text-purple-500 underline"
              >Privacy Policy</a>,
              and <a
                href="https://app.termly.io/policy-viewer/policy.html?policyUUID=5075835e-2802-4cc0-8dee-89b55b3ad41a"
                target="_blank"
                class="font-bold text-purple-600 hover:text-purple-500 underline"
              >Cookie Policy</a>.
            </label>
            <p class="text-gray-500 text-xs mt-2">
              By creating an account, you acknowledge that this platform processes Protected Health Information (PHI) in accordance with HIPAA regulations.
            </p>
          </div>
        </div>
        <:actions>
          <.button phx-disable-with="Creating account..." class="w-full">Create an account</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(%{"invite_token" => token}, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(invite_token: token)
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  @impl true
  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(invite_token: nil)
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:register, fn _repo, _changes ->
        Accounts.register_user(user_params)
      end)
      |> Ecto.Multi.run(:email, fn _repo, %{register: user} ->
        Accounts.deliver_user_confirmation_instructions(
          user,
          &url(~p"/users/confirm/#{&1}")
        )
      end)

    case Ankaa.Repo.transaction(multi) do
      {:ok, %{register: user}} ->
        login_token = Accounts.generate_temporary_login_token(user)

        return_to =
          case socket.assigns.invite_token do
            nil -> ~p"/portal"
            invite_token -> ~p"/invites/accept?token=#{invite_token}"
          end

        {:noreply,
         push_navigate(socket,
           to: ~p"/users/log_in_from_token?token=#{login_token}&return_to=#{return_to}"
         )}

      {:error, :register, changeset, _} ->
        {:noreply, assign(socket, form: to_form(changeset))}

      {:error, :email, _reason, _} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Registration failed. We couldn't send a confirmation email at this time."
         )}
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
