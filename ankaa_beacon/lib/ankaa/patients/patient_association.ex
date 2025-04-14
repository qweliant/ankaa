defmodule Ankaa.Patients.PatientAssociation do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ankaa.{Accounts.User, Patients.Patient}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "patient_associations" do
    field(:relationship, :string)
    field(:can_alert, :boolean, default: false)

    belongs_to(:user, User)
    belongs_to(:patient, Patient)

    timestamps()
  end

  def changeset(patient_association, attrs) do
    patient_association
    |> cast(attrs, [:relationship, :can_alert, :user_id, :patient_id])
    |> validate_required([:relationship, :can_alert, :user_id, :patient_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:patient_id)
    |> unique_constraint([:user_id, :patient_id],
      name: :patient_associations_user_id_patient_id_index,
      message: "Association between this user and patient already exists"
    )
  end
end
