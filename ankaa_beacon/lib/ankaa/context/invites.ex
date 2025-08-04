defmodule Ankaa.Invites do
  import Ecto.Query, warn: false
  alias Ankaa.Repo

  alias Ankaa.Mailer
  alias Ankaa.Invites.Invite
  alias Ankaa.Patients
  alias Ankaa.Accounts

  @rand_size 32

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
    cond do
      invite.invitee_role not in ["patient", "caresupport", "nurse", "doctor"] ->
        {:error, "Invalid invite role: #{invite.invitee_role}"}

      invite.invitee_role == "patient" ->
        accept_as_patient(user, invite)

      invite.invitee_role == "caresupport" ->
        accept_as_care_support(user, invite)

      invite.invitee_role == "careprovider" ->
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

  defp accept_as_patient(user, invite) do
    Repo.transaction(fn ->
      # This `with` block now handles both new and existing patients.
      with {:ok, patient_record} <- find_or_create_patient_for_user(user),
           inviter <- Accounts.get_user!(invite.inviter_id),
           {:ok, _} <- Patients.create_patient_association(inviter, patient_record, inviter.role),
           {:ok, updated_invite} <- update_invite_status(invite, "accepted") do
        updated_invite
      else
        # This will catch any errors and roll back the transaction.
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
        updated_invite
      else
        {:error, reason} -> Repo.rollback({:error, reason})
      end
    end)
  end

  defp accept_as_care_support(user, invite) do
    Repo.transaction(fn ->
      with patient <- Patients.get_patient!(invite.patient_id),
           {:ok, _relationship} <-
             Patients.create_patient_association(user, patient, "caresupport"),
           {:ok, updated_invite} <- update_invite_status(invite, "accepted") do
        updated_invite
      else
        {:error, reason} -> Repo.rollback({:error, reason})
      end
    end)
  end

  defp find_or_create_patient_for_user(user) do
    case Patients.get_patient_by_user_id(user.id) do
      nil ->
        # No patient record exists, so we create one.
        default_name =
          (user.first_name <> " " <> user.last_name)
          |> String.trim()
          |> case do
            "" -> user.email |> String.split("@") |> List.first() |> String.capitalize()
            full_name -> full_name
          end

        patient_attrs = %{"name" => default_name}
        Patients.create_patient(patient_attrs, user)

      existing_patient ->
        # A patient record already exists, so we just return it.
        {:ok, existing_patient}
    end
  end
end
