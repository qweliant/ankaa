defmodule Ankaa.Invites do
  import Ecto.Query, warn: false
  alias Ankaa.Repo

  alias Ankaa.Mailer
  alias Ankaa.Invites.Invite

  @rand_size 32
  @hash_algorithm :sha256

  @doc """
  Creates a new invite, saves its hash, and delivers the invite email in a single transaction.
  """
  def create_invite(inviter_user, invite_attrs) do
    # 1. Generate a secure, random token
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)
    expires_at = DateTime.add(DateTime.utc_now(), 7, :day)

    # 2. Build the map of server-generated attributes
    server_attrs = %{
      inviter_id: inviter_user.id,
      token: hashed_token,
      expires_at: expires_at,
      status: "pending"
    }

    # 3. Merge with form attributes and ensure all keys are strings to prevent cast errors
    final_attrs =
      invite_attrs
      |> Map.merge(server_attrs)
      |> Map.new(fn {k, v} -> {to_string(k), v} end)

    # 4. Use a `with` statement to chain the database insert and email delivery
    with {:ok, %Invite{} = invite} <- Repo.insert(Invite.changeset(%Invite{}, final_attrs)),
         # Send the ORIGINAL, unhashed token to the user's email
         email_token = Base.url_encode64(token, padding: false),
         {:ok, _email} <- Mailer.deliver_invite_email(invite, email_token) do
      {:ok, invite}
    else
      # This will catch errors from either the Repo.insert or the Mailer.deliver call
      {:error, _reason} = error -> error
    end
  end

  @doc """
  Finds a valid, pending invite by its token.
  It now hashes the incoming token to match what's in the database.
  """
  def get_pending_invite_by_token(token) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        from(i in Invite,
          where:
            i.token == ^hashed_token and
              i.status == "pending" and
              i.expires_at > ^DateTime.utc_now()
        )
        |> Repo.one()

      :error ->
        nil
    end
  end

  @doc """
  Checks if a pending invite already exists for a given email and patient.
  """
  def get_pending_invite_for_email_and_patient(email, patient_id) do
    from(i in Invite,
      where:
        i.invitee_email == ^email and
          i.patient_id == ^patient_id and
          i.status == "pending"
    )
    |> Repo.one()
  end

  def accept_invite(%Invite{} = invite) do
    invite
    |> Invite.changeset(%{status: "accepted"})
    |> Repo.update()
  end
end
