defmodule Ankaa.Patients.CareNetwork do
  @moduledoc """
  Schema for the care_network table, representing associations between patients and their care network members.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ankaa.{Accounts.User, Patients.Patient}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @roles [
    :admin,
    :doctor,
    :nurse,
    :caresupport,
    :technical_support,
    :clinic_technician,
    :social_worker,
    :patient
  ]
  @permissions [:owner, :admin, :contributor, :viewer]
  schema "care_network" do
    field(:relationship, :string)
    field(:fridge_card_notes, :string)
    field(:role, Ecto.Enum, values: @roles)
    field(:permission, Ecto.Enum, values: @permissions, default: :viewer)

    belongs_to(:user, User, foreign_key: :user_id)
    belongs_to(:patient, Patient, foreign_key: :patient_id)

    timestamps()
  end

  def changeset(patient_association, attrs) do
    patient_association
    |> cast(attrs, [:relationship, :patient_id, :user_id, :fridge_card_notes, :role, :permission])
    |> validate_required([:relationship, :patient_id, :user_id, :role, :permission])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:patient_id)
    |> unique_constraint([:user_id, :patient_id],
      name: :patient_associations_user_id_patient_id_index,
      message: "Association between this user and patient already exists"
    )

    # |> validate_inclusion(:relationship, @relationships)
  end

  def valid_roles, do: @roles
  def valid_permissions, do: @permissions
  def valid_relationships, do: @relationships
end
