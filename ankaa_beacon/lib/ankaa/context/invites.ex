defmodule Ankaa.Invites do
  import Ecto.Query, warn: false
  alias Ankaa.Repo

  alias Ankaa.Mailer
  alias Ankaa.Invites.Invite
  alias Ankaa.Patients
  alias Ankaa.Accounts

  @rand_size 32
  # @hash_algorithm :sha256

  @doc """
  Creates a new invite, saves its hash, and delivers the invite email in a single transaction.
  """
  def create_invite(inviter_user, invite_attrs) do
    # token = :crypto.strong_rand_bytes(@rand_size)
    # hashed_token = :crypto.hash(@hash_algorithm, token)
    # encoded_token = Base.encode16(hashed_token, case: :lower)
    token = :crypto.strong_rand_bytes(@rand_size) |> Base.url_encode64(padding: false)
    expires_at = DateTime.add(DateTime.utc_now(), 7, :day)

    final_attrs =
      invite_attrs
      |> Map.put("inviter_id", inviter_user.id)
      |> Map.put("token", token)
      |> Map.put("expires_at", expires_at)
      |> Map.put("status", "pending")
      |> Map.new(fn {k, v} -> {to_string(k), v} end)

    IO.inspect(final_attrs, label: "[INVITES CONTEXT] Attributes for new invite:")

    Repo.transaction(fn ->
      case Repo.insert(Invite.changeset(%Invite{}, final_attrs)) do
        {:ok, invite} ->
          case Mailer.deliver_invite_email(invite, token) do
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
    # No more decoding or hashing needed!
    from(i in Invite,
      where:
        i.token == ^token and
          i.status == "pending" and
          i.expires_at > ^DateTime.utc_now()
    )
    |> Repo.one()
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

  @doc """
  Accepts an invitation, creates the patient association, and updates the
  invite status within a single transaction.
  """
  def accept_invite(user, %Invite{} = invite) do
    if invite.invitee_role == "patient" do
      accept_as_new_patient(user, invite)
    else
      accept_as_care_provider(user, invite)
    end
  end

  @doc false
  # A helper to update the invite status.
  defp update_invite_status(invite, status) do
    invite
    |> Invite.changeset(%{status: status})
    |> Repo.update()
  end

  defp accept_as_new_patient(user, invite) do
    Repo.transaction(fn ->
      default_name = user.email |> String.split("@") |> List.first() |> String.capitalize()
      patient_attrs = %{"name" => default_name}

      with {:ok, patient_record} <- Patients.create_patient(patient_attrs, user),
           inviter <- Accounts.get_user!(invite.inviter_id),
           {:ok, _} <- Patients.create_patient_association(inviter, patient_record, inviter.role),
           {:ok, updated_invite} <- update_invite_status(invite, "accepted") do
        # Return the invite directly, not in a tuple.
        updated_invite
      else
        {:error, reason} -> Repo.rollback({:error, reason})
      end
    end)
  end

  defp accept_as_care_provider(user, invite) do
    Repo.transaction(fn ->
      with patient <- Patients.get_patient!(invite.patient_id),
           {:ok, _relationship} <-
             Patients.create_patient_association(user, patient, invite.invitee_role),
           {:ok, updated_invite} <- update_invite_status(invite, "accepted") do
        # Return the invite directly, not in a tuple.
        updated_invite
      else
        {:error, reason} -> Repo.rollback({:error, reason})
      end
    end)
  end
end
