defmodule Ankaa.Invites.Invite do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ["pending", "accepted", "expired"]
  @roles ["caresupport", "nurse", "doctor"]

  schema "invites" do
    field(:invitee_email, :string)
    field(:invitee_role, :string)
    field(:token, :string)
    field(:status, :string, default: "pending")
    field(:expires_at, :utc_datetime)

    belongs_to(:inviter, Ankaa.Accounts.User, foreign_key: :inviter_id, type: :binary_id)

    # The patient this invite is for (can be null if it's a general invite)
    belongs_to(:patient, Ankaa.Patients.Patient, foreign_key: :patient_id, type: :binary_id)

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
      :patient_id
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
  end
end
