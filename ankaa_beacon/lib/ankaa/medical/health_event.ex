defmodule Ankaa.Medical.HealthEvent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @types [:vital, :mood, :symptom, :medication, :note]
  schema "health_events" do
    field :type, Ecto.Enum, values: @types
    field :category, :string
    field :data, :map # JSON structure
    field :occurred_at, :utc_datetime

    belongs_to :patient, Ankaa.Patients.Patient
    belongs_to :logged_by, Ankaa.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(health_event, attrs) do
    health_event
    |> cast(attrs, [:type, :category, :data, :occurred_at, :patient_id, :logged_by_id])
    |> validate_required([:type, :category, :occurred_at, :patient_id])
    |> validate_data_structure()
  end

  # TODO: Ensure the JSON has the right keys based on category
  defp validate_data_structure(changeset) do
    # add logic like "If category is 'blood_pressure', data MUST have 'systolic' and 'diastolic'"
    changeset
  end
end
