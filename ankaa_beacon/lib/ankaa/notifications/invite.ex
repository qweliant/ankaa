defmodule Ankaa.Notifications.Invite do
  @moduledoc """
  The Role Invite schema.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ankaa.Patients.Patient
  alias Ankaa.Community.Organization

  @statuses ["pending", "accepted", "expired"]
  @roles [
    "caresupport",
    "nurse",
    "doctor",
    "patient",
    "clinic_technician",
    "community_coordinator",
    "social_worker"
  ]

  # The permissions they will inherit.
  # :owner -> Can delete the hub
  # :admin -> Can manage meds/files (Spouse/Doctor)
  # :member / :contributor -> Can log vitals (Caregiver)
  # :viewer -> Read only (Distant family)
  @access_roles ["owner", "admin", "moderator", "member", "contributor", "viewer"]

  schema "invites" do
    field(:invitee_email, :string)
    field(:invitee_role, :string)
    field(:invitee_permission, :string)

    field(:token, :string)
    field(:status, :string, default: "pending")
    field(:expires_at, :utc_datetime)

    belongs_to(:inviter, Ankaa.Accounts.User, foreign_key: :inviter_id, type: :binary_id)
    belongs_to(:patient, Patient, foreign_key: :patient_id, type: :binary_id)
    belongs_to(:organization, Organization, foreign_key: :organization_id, type: :binary_id)
    timestamps()
  end

  def changeset(invite, attrs) do
    invite
    |> cast(attrs, [
      :invitee_email,
      :invitee_role,
      :token,
      :status,
      :expires_at,
      :inviter_id,
      :patient_id,
      :invitee_permission,
      :organization_id
    ])
    |> validate_required([
      :invitee_email,
      :invitee_role,
      :token,
      :status,
      :expires_at,
      :inviter_id
    ])
    |> validate_format(:invitee_email, ~r/^[^\s]+@[^\s]+$/)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:invitee_permission, @access_roles)
    |> validate_inclusion(:invitee_role, @roles)
    |> foreign_key_constraint(:inviter_id)
    |> validate_one_target()
  end

  defp validate_one_target(changeset) do
    org_id = get_field(changeset, :organization_id)
    pat_id = get_field(changeset, :patient_id)
    role   = get_field(changeset, :invitee_role)

    has_destination? = not is_nil(org_id) or not is_nil(pat_id)
    cond do
      # having an org id and a patient id at the same time doesn't make sense, regardless of role -> ERROR
      role == "patient" and not has_destination? ->
        changeset

      # no org and no patient id is valid if the role is "patient" because creating a new patient
      # record doesn't require an existing patient or org
      has_destination? ->
        changeset

      # no org and no patient id is not valid without a "patient" role -> Error (Colleagues need a destination)
      true ->
        add_error(changeset, :base, "Must invite to either an Organization or a Patient")
    end
  end
end
