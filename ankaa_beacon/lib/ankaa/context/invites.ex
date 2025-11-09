defmodule Ankaa.Invites do
  @moduledoc """
  The Invites context.
  """
  import Ecto.{Query}, warn: false

  alias Ankaa.Repo

  alias Ankaa.Mailer
  
  alias Ankaa.Notifications.Invite
  alias Ankaa.Patients
  alias Ankaa.Accounts

  @rand_size 32

  @allowed_invites %{
    "patient" => ["caresupport", "doctor", "nurse"],
    "doctor" => ["patient"],
    "nurse" => ["patient"],
    "caresupport" => []
  }

  @doc """
  Authorizes, validates, and creates a new invite.
  """
  def send_invitation(inviter_user, patient, invite_params) do
    with :ok <- authorize_invite(inviter_user, invite_params["invitee_role"]),
         :ok <- validate_self_invite(inviter_user, invite_params["invitee_email"]),
         :ok <-
           validate_existing_user(invite_params["invitee_email"], invite_params["invitee_role"]),
         :ok <- validate_pending_invite(invite_params["invitee_email"], patient.id) do
      attrs = Map.put(invite_params, "patient_id", patient.id)
      create_invite(inviter_user, attrs)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Creates a new invite, saves its hash, and delivers the invite email in a single transaction.
  """
  @dialyzer {:nowarn_function, create_invite: 2}
  def create_invite(inviter_user, invite_attrs) do
    token = :crypto.strong_rand_bytes(@rand_size) |> Base.url_encode64(padding: false)
    expires_at = DateTime.add(DateTime.utc_now(), 7, :day)

    final_attrs =
      invite_attrs
      |> Map.put("inviter_id", inviter_user.id)
      |> Map.put("token", token)
      |> Map.put("expires_at", expires_at)
      |> Map.put("status", "pending")
      |> Map.new(fn {k, v} -> {to_string(k), v} end)

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:invite, Invite.changeset(%Invite{}, final_attrs))
      |> Ecto.Multi.run(:email, fn _repo, %{invite: invite} ->
        case Mailer.deliver_invite_email(invite, token) do
          {:ok, _delivery_details} ->
            # Report success
            {:ok, :email_sent}

          {:error, reason} ->
            # Report failure, this will roll back the transaction
            {:error, reason}
        end
      end)

    case Repo.transaction(multi) do
      {:ok, %{invite: invite}} ->
        {:ok, invite}

      {:error, :invite, changeset, _} ->
        {:error, changeset}

      {:error, :email, email_error, _} ->
        {:error, {:error, email_error}}
    end
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
      invite.invitee_role == "patient" ->
        accept_as_patient(user, invite)

      invite.invitee_role == "caresupport" ->
        accept_as_care_support(user, invite)

      # Check if the role is either "doctor" OR "nurse"
      invite.invitee_role in ["doctor", "nurse"] ->
        accept_as_care_provider(user, invite)

      # It's good practice to have a final "else" clause to catch anything unexpected.
      true ->
        {:error, "Invalid or unhandled invite role: #{invite.invitee_role}"}
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
      with {:ok, user_with_role} <- Accounts.assign_role(user, invite.invitee_role),
           patient <- Patients.get_patient!(invite.patient_id),
           {:ok, _relationship} <-
             Patients.create_patient_association(user_with_role, patient, invite.invitee_role),
           {:ok, updated_invite} <- update_invite_status(invite, "accepted") do
        updated_invite
      else
        {:error, reason} -> Repo.rollback({:error, reason})
      end
    end)
  end

  defp accept_as_care_support(user, invite) do
    Repo.transaction(fn ->
      with {:ok, user_with_role} <- Accounts.assign_role(user, "caresupport"),
           patient <- Patients.get_patient!(invite.patient_id),
           {:ok, _relationship} <-
             Patients.create_patient_association(user_with_role, patient, "caresupport"),
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
          if user.first_name && user.last_name do
            # If we have both names, use them.
            "#{user.first_name} #{user.last_name}"
          else
            # Otherwise, fall back to the email address.
            user.email |> String.split("@") |> List.first() |> String.capitalize()
          end

        patient_attrs = %{"name" => default_name}
        Patients.create_patient(patient_attrs, user)

      existing_patient ->
        # A patient record already exists, so we just return it.
        {:ok, existing_patient}
    end
  end

  defp authorize_invite(inviter_user, invitee_role) do
    inviter_role = if Accounts.User.patient?(inviter_user), do: "patient", else: inviter_user.role
    allowed_roles = Map.get(@allowed_invites, inviter_role, [])

    if invitee_role in allowed_roles do
      :ok
    else
      {:error, "A #{inviter_role} is not authorized to invite a #{invitee_role}."}
    end
  end

  defp validate_self_invite(inviter_user, invitee_email) do
    if inviter_user.email == invitee_email do
      {:error, "You cannot invite yourself to your own care network."}
    else
      :ok
    end
  end

  defp validate_existing_user(invitee_email, invitee_role) do
    case Accounts.get_user_by_email(invitee_email) do
      nil ->
        # No user exists, so no conflict.
        :ok

      existing_user ->
        # A user exists, but their role is different AND not nil
        if existing_user.role != invitee_role and !is_nil(existing_user.role) do
          {:error,
           "A user with email #{invitee_email} already exists with the role '#{existing_user.role}'. You cannot invite them as a '#{invitee_role}'."}
        else
          # User exists but role matches (or is nil), which is fine.
          :ok
        end
    end
  end

  defp validate_pending_invite(invitee_email, patient_id) do
    if get_pending_invite_for_email_and_patient(invitee_email, patient_id) do
      {:error, "An invitation has already been sent to #{invitee_email} and is still pending."}
    else
      :ok
    end
  end
end
