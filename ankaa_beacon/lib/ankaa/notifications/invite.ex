defmodule Ankaa.Notifications.Invite do
  @moduledoc """
  The Role Invite schema.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ankaa.Accounts.Organization

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

  schema "invites" do
    field(:invitee_email, :string)
    field(:invitee_role, :string)
    field(:token, :string)
    field(:status, :string, default: "pending")
    field(:expires_at, :utc_datetime)

    belongs_to(:inviter, Ankaa.Accounts.User, foreign_key: :inviter_id, type: :binary_id)
    # The patient this invite is for (can be null if it's a general invite)
    belongs_to(:patient, Ankaa.Patients.Patient, foreign_key: :patient_id, type: :binary_id)
    belongs_to(:organization, Organization)

    timestamps()
  end

  @doc false
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
    |> validate_inclusion(:invitee_role, @roles)
    |> foreign_key_constraint(:inviter_id)
    |> foreign_key_constraint(:patient_id)
    # |> validate_organization_required_for_staff()
  end

  # defp validate_organization_required_for_staff(changeset) do
  #   role = get_field(changeset, :invitee_role)
  #   org_id = get_field(changeset, :organization_id)

  #   # If inviting a staff member, Organization ID is required
  #   if role in ["doctor", "nurse", "clinic_technician"] and is_nil(org_id) do
  #     add_error(changeset, :organization_id, "must be present when inviting staff")
  #   else
  #     changeset
  #   end
  # end
end
