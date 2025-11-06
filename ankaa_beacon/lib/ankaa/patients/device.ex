defmodule Ankaa.Patients.Device do
  @moduledoc """
  Ecto schema for patient devices.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "devices" do
    field(:type, :string)
    field(:model, :string)
    field(:simulation_scenario, :string)
    belongs_to(:patient, Ankaa.Patients.Patient, foreign_key: :patient_id)
    timestamps()
  end

  def changeset(device, attrs) do
    device
    |> cast(attrs, [:type, :model, :patient_id, :simulation_scenario])
    |> validate_required([:type, :patient_id, :simulation_scenario])
    |> foreign_key_constraint(:patient_id)
  end
end
