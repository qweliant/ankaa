defmodule Ankaa.Patients.Patient do
  @moduledoc """
  The Patient schema.
  """
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

    belongs_to(:owner, User, foreign_key: :user_id) # this person created the care network

    has_many(:memberships, Ankaa.Patients.CareNetwork)
    has_many(:members, through: [:memberships, :user])
    has_many(:devices, Ankaa.Patients.Device)

    timestamps()
  end

  def changeset(patient, attrs) do
    patient
    |> cast(attrs, [:external_id, :name, :date_of_birth, :timezone, :user_id])
    |> validate_required([:name])
    |> unique_constraint(:external_id)
    |> foreign_key_constraint(:user_id)
  end
end
