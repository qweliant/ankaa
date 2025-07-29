defmodule AnkaaWeb.AcceptInviteLive do
  use AnkaaWeb, :live_view

  alias Ankaa.Accounts
  alias Ankaa.Invites
  alias AnkaaWeb.UserAuth

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Accepting Invitation...")}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, :handle_invite, params)}
  end

  defp apply_action(socket, :handle_invite, %{"token" => token}) do
    IO.inspect(token, label: "INVITE TOKEN")

    socket
    # only assign if not already set
    |> assign_new(:invite, fn -> Invites.get_pending_invite_by_token(token) end)
    |> handle_invite_logic(token)
  end

  # Do nothing if no token
  defp apply_action(socket, _, _), do: socket

  # Case 1: The token is invalid or expired. This is the first check.
  defp handle_invite_logic(%{assigns: %{invite: nil}} = socket, _original_token) do
    socket
    |> put_flash(:error, "This invitation is invalid or has expired.")
    |> push_navigate(to: ~p"/")
  end

  # Case 2: User IS logged in. This is the most specific case for a valid invite.
  # The `when not is_nil(user)` guard makes sure this only matches for logged-in users.
  defp handle_invite_logic(
         %{assigns: %{current_user: user, invite: invite}} = socket,
         _original_token
       )
       when not is_nil(user) do
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
        {:ok, _} = Invites.accept_invite(user, invite)

        socket
        |> put_flash(:info, "Invitation accepted! You've been added to the care network.")
        |> push_navigate(to: ~p"/")
    end
  end

  # Case 3: User is NOT logged in. This now acts as a catch-all for any valid invite
  # that didn't match the logged-in case above.
  defp handle_invite_logic(%{assigns: %{invite: invite}} = socket, original_token) do
    IO.inspect(invite, label: "INVITE")

    invited_user = Accounts.get_user_by_email(invite.invitee_email)

    if invited_user do
      # A user with this email exists. Redirect to login.
      socket
      |> put_flash(:info, "Please log in to accept your invitation.")
      |> push_navigate(to: ~p"/users/login?invite_token=#{original_token}")
    else
      # No user exists. Redirect to registration.
      socket
      |> put_flash(:info, "Please create an account to accept your invitation.")
      |> push_navigate(to: ~p"/users/register?invite_token=#{original_token}")
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
