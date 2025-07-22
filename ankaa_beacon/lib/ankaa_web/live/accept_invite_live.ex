defmodule AnkaaWeb.AcceptInviteLive do
  use AnkaaWeb, :live_view

  alias Ankaa.Accounts
  alias Ankaa.Invites
  # import Phoenix.Controller, only: [put_session: 3]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Accepting Invitation...")}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, :handle_invite, params)}
  end

  defp apply_action(socket, :handle_invite, %{"token" => token}) do
    socket
    |> assign_new(:invite, fn -> Invites.get_pending_invite_by_token(token) end)
    |> handle_invite_logic()
  end

  # Do nothing if no token
  defp apply_action(socket, _, _), do: socket

  defp handle_invite_logic(%{assigns: %{invite: nil}} = socket) do
    # Case 1: The token is invalid or expired.
    socket
    |> put_flash(:error, "This invitation is invalid or has expired.")
    |> push_navigate(to: ~p"/")
  end

  defp handle_invite_logic(%{assigns: %{current_user: nil, invite: invite}} = socket) do
    # Case 2: User is NOT logged in.
    invited_user = Accounts.get_user_by_email(invite.invitee_email)

    if invited_user do
      # A user with this email exists. Redirect to login.
      socket
      |> Phoenix.LiveView.put_session(:invite_token, invite.token)
      |> put_flash(:info, "Please log in to accept your invitation.")
      |> push_navigate(to: ~p"/users/login")
    else
      # No user exists. Redirect to registration.
      socket
      |> put_flash(:info, "Please create an account to accept your invitation.")
      |> push_navigate(to: ~p"/users/register?invite_token=#{invite.token}")
    end
  end

  defp handle_invite_logic(%{assigns: %{current_user: user, invite: invite}} = socket) do
    # Case 3: User IS logged in.
    cond do
      user.email != invite.invitee_email ->
        socket
        |> put_flash(:error, "This invitation is for a different email address.")
        |> push_navigate(to: ~p"/")

      user.id == invite.inviter_id ->
        socket
        |> put_flash(:error, "You cannot accept an invitation you sent.")
        |> push_navigate(to: ~p"/")

      true ->
        # Success! The right user is logged in.
        # Here we would add them to the care network.
        # For now, we'll just accept the invite and redirect.
        {:ok, _} = Invites.accept_invite(invite)

        socket
        |> put_flash(:info, "Invitation accepted! You've been added to the care network.")
        # Or wherever they should go
        |> push_navigate(to: ~p"/patient/monitoring")
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center p-20">
      <div class="text-center">
        <p class="text-xl font-semibold">Processing your invitation...</p>
        <p class="text-gray-500">Please wait while we redirect you.</p>
      </div>
    </div>
    """
  end
end
