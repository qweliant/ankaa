defmodule Ankaa.Invites do
  import Ecto.Query, warn: false
  alias Ankaa.Repo

  alias Ankaa.Accounts
  alias Ankaa.Mailer
  alias Ankaa.Invites.Invite

  @doc """
  Creates a new invite, saves it to the database, and triggers the invite email.
  This is the main function we'll call from our LiveView.
  """
  def create_invite(inviter_user, invite_attrs) do
    token = Accounts.generate_token()
    expires_at = DateTime.add(DateTime.utc_now(), 7, :day)

    attrs =
      Map.merge(invite_attrs, %{
        inviter_id: inviter_user.id,
        token: token,
        expires_at: expires_at,
        status: "pending"
      })

    with {:ok, %Invite{} = invite} <- Repo.insert(Invite.changeset(%Invite{}, attrs)),
         {:ok, _} <- Mailer.deliver_invite_email(invite) do
      {:ok, invite}
    else
      {:error, _reason} = error -> error
    end
  end

  @doc """
  Finds a valid, pending invite by its token.
  """
  def get_pending_invite_by_token(token) do
    from(i in Invite,
      where: i.token == ^token and i.status == "pending" and i.expires_at > ^DateTime.utc_now()
    )
    |> Repo.one()
  end

  @doc """
  Marks an invite as accepted.
  """
  def accept_invite(%Invite{} = invite) do
    invite
    |> Invite.changeset(%{status: "accepted"})
    |> Repo.update()
  end
end
