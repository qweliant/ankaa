defmodule Ankaa.Invites do
  @moduledoc """
  The Invites context.
  """
  import Ecto.{Query}, warn: false

  alias Ankaa.Communities
  alias Ankaa.Repo

  alias Ankaa.Mailer

  alias Ankaa.Notifications.Invite
  alias Ankaa.Patients
  alias Ankaa.Accounts

  require Logger

  @rand_size 32

  @allowed_invites %{
    "patient" => ["caresupport", "doctor", "nurse"],
    "doctor" => ["patient"],
    "nurse" => ["patient"],
    "caresupport" => []
  }

  @permission_ranks %{
    owner: 4,
    admin: 3,
    contributor: 2,
    viewer: 1
  }

  @doc """
  Authorizes, validates, and creates a new invite.
  """
  def send_invitation(inviter_user, patient, invite_params) do
    with :ok <- authorize_invite(inviter_user, patient, invite_params),
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
  def create_invite(inviter_user, invite_attrs) do
    token = :crypto.strong_rand_bytes(@rand_size) |> Base.url_encode64(padding: false)
    expires_at = DateTime.add(DateTime.utc_now(), 7, :day)

    final_attrs =
      invite_attrs
      |> Map.put("inviter_id", inviter_user.id)
      |> Map.put("token", token)
      |> Map.put("expires_at", expires_at)
      |> Map.put("status", "pending")
      |> Map.put("invitee_permission", to_string(invite_attrs["invitee_permission"] || :viewer))
      |> Map.new(fn {k, v} -> {to_string(k), v} end)

    # We use Ecto.Multi to ensure that if the email fails to send, the invite creation is rolled back.
    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:invite, Invite.changeset(%Invite{}, final_attrs))
      |> Ecto.Multi.run(:email, fn _repo, %{invite: invite} ->
        case Mailer.deliver_invite_email(invite, token) do
          {:ok, _delivery_details} ->
            {:ok, :email_sent}

          {:error, reason} ->
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
    Repo.transaction(fn ->
      with {:ok, _result} <- process_target(user, invite),
           {:ok, updated_invite} <- update_status(invite, "accepted") do
        updated_invite
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @doc false
  # A helper to update the invite status.
  defp process_target(user, invite) do
    cond do
      invite.invitee_role == "patient" ->
        accept_as_patient(user, invite)

      invite.invitee_role == "caresupport" ->
        accept_as_care_support(user, invite)

      # Care provider Flow (Doctor, Nurse, Tech, Social Worker)
      invite.invitee_role in ["doctor", "nurse", "clinic_technician", "social_worker"] ->
        # Check the Invite Target to decide the strategy
        if invite.patient_id do
          # If there is a patient attached, they are a Care Provider
          accept_as_care_provider(user, invite)
        else
          # If no patient, they are just joining the Organization as a Colleague
          accept_as_colleague(user, invite)
        end

      invite.organization_id ->
        Communities.add_member(user, invite.organization_id, invite.invitee_role)

      true ->
        {:error, "Invite is missing a target (patient_id or organization_id)"}
    end
  end

  defp update_invite_status(invite, status) do
    invite
    |> Invite.changeset(%{status: status})
    |> Repo.update()
  end

  defp accept_as_patient(user, invite) do
    permission = String.to_existing_atom(invite.invitee_permission || "owner")

    Repo.transaction(fn ->
      with {:ok, patient_record} <- find_or_create_patient_for_user(user),
           inviter <- Accounts.get_user!(invite.inviter_id),
           {:ok, _} <-
             Patients.create_patient_association(
               inviter,
               patient_record,
               "Patient of {#{inviter.first_name} #{inviter.last_name}}",
               permission,
               inviter.role
             ),
           {:ok, _} <-
             (if invite.organization_id do
                Communities.add_member(user, invite.organization_id, "admin")
              else
                {:ok, nil}
              end),
           {:ok, updated_invite} <- update_invite_status(invite, "accepted") do
        updated_invite
      else
        {:error, reason} -> Repo.rollback({:error, reason})
      end
    end)
  end

  defp accept_as_care_provider(user, invite) do
    Repo.transaction(fn ->
      patient = Patients.get_patient!(invite.patient_id)

      # ReBAC Attributes
      # Badge: "Doctor"
      relationship = String.capitalize(invite.invitee_role)
      # Hat: :doctor
      role = safe_to_atom(invite.invitee_role)
      # Keys: :contributor
      permission = safe_to_atom(invite.invitee_permission || "contributor")

      with {:ok, _} <-
             Patients.create_patient_association(user, patient, relationship, permission, role),
           {:ok, _} <-
             if(invite.organization_id,
               do: Communities.add_member(user, invite.organization_id, "member"),
               else: {:ok, nil}
             ),
           {:ok, updated} <- update_invite_status(invite, "accepted") do
        updated
      else
        {:error, reason} -> Repo.rollback({:error, reason})
      end
    end)
  end

  defp accept_as_care_support(user, invite) do
    Repo.transaction(fn ->
      patient = Patients.get_patient!(invite.patient_id)

      # ReBAC Attributes for Family
      relationship = invite.invitee_relationship || "Family"
      role = :caresupport
      permission = safe_to_atom(invite.invitee_permission || :contributor)

      with {:ok, _} <-
             Patients.create_patient_association(user, patient, relationship, permission, role),
           {:ok, updated} <- update_invite_status(invite, "accepted") do
        updated
      else
        {:error, reason} -> Repo.rollback({:error, reason})
      end
    end)
  end

  defp accept_as_colleague(user, invite) do
    Repo.transaction(fn ->
      if invite.organization_id do
        Communities.add_member(user, invite.organization_id, "member")
      end

      update_invite_status(invite, "accepted")
    end)
  end

  defp find_or_create_patient_for_user(user) do
    case Patients.get_patient_by_user_id(user.id) do
      nil ->
        default_name = "#{user.first_name} #{user.last_name}" |> String.trim()
        default_name = if default_name == "", do: user.email, else: default_name

        Patients.create_patient(%{"name" => default_name}, user)

      existing ->
        {:ok, existing}
    end
  end

  defp authorize_invite(inviter_user, patient, invite_params) do
    target_role = invite_params["invitee_role"]
    target_permission = safe_to_atom(invite_params["invitee_permission"] || "viewer")

    case Patients.get_care_network_entry(inviter_user.id, patient.id) do
      nil ->
        {:error, "You are not a member of this care network."}

      %Ankaa.Patients.CareNetwork{role: inviter_role, permission: inviter_perm} ->
        allowed_roles = Map.get(@allowed_invites, inviter_role, [])

        role_check =
          if target_role in allowed_roles do
            :ok
          else
            {:error, "A #{inviter_role} cannot invite a #{target_role}."}
          end

        perm_check = validate_permission_hierarchy(inviter_perm, target_permission)

        with :ok <- role_check,
             :ok <- perm_check do
          :ok
        end
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
    :ok
  end

  defp validate_pending_invite(invitee_email, patient_id) do
    if get_pending_invite_for_email_and_patient(invitee_email, patient_id) do
      {:error, "An invitation has already been sent to #{invitee_email} and is still pending."}
    else
      :ok
    end
  end

  defp update_status(invite, status) do
    invite
    |> Invite.changeset(%{status: status})
    |> Repo.update()
  end

  defp safe_to_atom(str) when is_binary(str) do
    String.to_existing_atom(str)
  rescue
    _ ->
      :viewer
  end

  defp safe_to_atom(atom) when is_atom(atom), do: atom

  defp validate_permission_hierarchy(inviter_perm, target_perm) do
    inviter_rank = Map.get(@permission_ranks, inviter_perm, 0)
    target_rank = Map.get(@permission_ranks, target_perm, 0)

    cond do
      # Viewers cannot invite anyone
      inviter_perm == :viewer ->
        {:error, "Viewers do not have permission to send invites."}

      # Cannot grant higher permission than you possess
      # e.g. Contributor (2) cannot invite an Admin (3)
      inviter_rank < target_rank ->
        {:error,
         "You cannot grant a permission level (#{target_perm}) higher than your own (#{inviter_perm})."}

      true ->
        :ok
    end
  end
end
