defmodule AnkaaWeb.TokenRegistrationLive do
  use AnkaaWeb, :live_view
  import AnkaaWeb.UserAuth

  alias Ankaa.Accounts
  alias Ankaa.UserAuth

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{"token" => ""}, as: :user))}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    {:noreply, assign(socket, form: to_form(user_params, as: :user))}
  end

  def handle_event("save", %{"user" => %{"token" => token}}, socket) do
    case token do
      "patient" ->
        {:noreply, push_navigate(socket, to: ~p"/patients/entry")}

      role when role in ["doctor", "nurse", "admin", "caregiver", "technical_support"] ->
        case Accounts.assign_role(socket.assigns.current_user, role) do
          {:ok, _user} ->
            {:noreply,
             push_navigate(socket,
               to:
                 signed_in_path(%Plug.Conn{assigns: %{current_user: socket.assigns.current_user}})
             )}

          {:error, _changeset} ->
            {:noreply,
             socket
             |> put_flash(:error, "Failed to assign role. Please try again.")
             |> assign(form: to_form(%{"token" => ""}, as: :user))}
        end

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid token. Please try again.")
         |> assign(form: to_form(%{"token" => ""}, as: :user))}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Enter Registration Token
        <:subtitle>Please enter the token you received to continue with registration.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="token_form"
        phx-submit="save"
        phx-change="validate"
      >
        <.input field={@form[:token]} type="text" label="Token" required />
        <:actions>
          <.button phx-disable-with="Processing..." class="w-full">
            Continue
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
