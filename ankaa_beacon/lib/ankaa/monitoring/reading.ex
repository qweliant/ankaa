defmodule Ankaa.Monitoring.Reading do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "readings" do
    field(:device_id, :binary_id)
    field(:payload, :map)
    field(:recorded_at, :utc_datetime)

    belongs_to(:patient, Ankaa.Patients.Patient)

    timestamps()
  end

  @doc false
  def changeset(reading, attrs) do
    reading
    |> cast(attrs, [:patient_id, :device_id, :payload, :recorded_at])
    |> validate_required([:patient_id, :device_id, :payload, :recorded_at])
  end
end
