defmodule Ankaa.Patients.Patient do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ankaa.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "patients" do
    field(:external_id, :string)
    field(:name, :string)
    field(:date_of_birth, :date)
    field(:timezone, :string)
    field(:device_id, :string)

    belongs_to(:user, User, foreign_key: :user_id)
    has_many(:patient_associations, Ankaa.Patients.PatientAssociation)
    has_many(:associated_users, through: [:patient_associations, :user])

    timestamps()
  end

  def changeset(patient, attrs) do
    patient
    |> cast(attrs, [:external_id, :name, :date_of_birth, :timezone, :device_id, :user_id])
    |> validate_required([:name, :user_id])
    |> unique_constraint(:external_id)
    |> unique_constraint(:device_id)
    |> foreign_key_constraint(:user_id)
  end
end
