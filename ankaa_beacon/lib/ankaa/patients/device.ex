defmodule Ankaa.Patients.Device do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "devices" do
    field(:type, :string)
    field(:model, :string)
    field(:device_id, :string)
    field(:simulation_scenario, :string)
    belongs_to(:patient, Ankaa.Patients.Patient, foreign_key: :patient_id)
    timestamps()
  end

  def changeset(device, attrs) do
    device
    |> cast(attrs, [:type, :model, :device_id, :patient_id, :simulation_scenario])
    |> validate_required([:type, :device_id, :patient_id, :simulation_scenario])
    |> unique_constraint([:patient_id, :device_id],
      name: :devices_patient_id_device_id_index
    )
    |> foreign_key_constraint(:patient_id)
  end
end
