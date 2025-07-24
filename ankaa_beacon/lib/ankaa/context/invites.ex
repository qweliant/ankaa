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
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)
    encoded_token = Base.encode16(hashed_token, case: :lower)
    expires_at = DateTime.add(DateTime.utc_now(), 7, :day)

    final_attrs =
      invite_attrs
      |> Map.put("inviter_id", inviter_user.id)
      |> Map.put("token", encoded_token)
      |> Map.put("expires_at", expires_at)
      |> Map.put("status", "pending")
      |> Map.new(fn {k, v} -> {to_string(k), v} end)

    IO.inspect(final_attrs, label: "[INVITES CONTEXT] Attributes for new invite:")

    Repo.transaction(fn ->
      case Repo.insert(Invite.changeset(%Invite{}, final_attrs)) do
        {:ok, invite} ->
          email_token = Base.url_encode64(token, padding: false)

          case Mailer.deliver_invite_email(invite, email_token) do
            {:ok, _delivery_details} ->
              invite

            {:error, _reason} ->
              Repo.rollback("email_delivery_failed")
          end

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Finds a valid, pending invite by its token.
  It now hashes the incoming token to match what's in the database.
  """
  def get_pending_invite_by_token(token) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        encoded_hashed_token = Base.encode16(hashed_token, case: :lower)

        from(i in Invite,
          where:
            i.token == ^encoded_hashed_token and
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
