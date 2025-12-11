defmodule Ankaa.Medical.Medication do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "medications" do
    field :name, :string
    field :strength, :string
    field :frequency, :string
    field :instructions, :string
    field :photo_url, :string
    field :is_active, :boolean, default: true

    belongs_to :patient, Ankaa.Patients.Patient

    timestamps(type: :utc_datetime)
  end

  def changeset(medication, attrs) do
    medication
    |> cast(attrs, [:name, :strength, :frequency, :instructions, :photo_url, :is_active, :patient_id])
    |> validate_required([:name, :patient_id])
  end
end
