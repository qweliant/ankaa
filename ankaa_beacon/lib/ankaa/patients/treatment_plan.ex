defmodule Ankaa.Patients.TreatmentPlan do
  @moduledoc """
  Ecto schema for patient treatment plans.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "treatment_plans" do
    field(:frequency, :string)
    field(:duration_minutes, :integer)
    field(:blood_flow_rate, :integer)
    field(:dialysate_flow_rate, :integer)
    field(:target_ultrafiltration, :float)
    field(:dry_weight, :float)
    field(:access_type, :string)
    field(:notes, :string)

    belongs_to :patient, Ankaa.Patients.Patient
    belongs_to :prescribed_by, Ankaa.Accounts.User

    timestamps()
  end

  def changeset(plan, attrs) do
    plan
    |> cast(attrs, [
      :frequency,
      :duration_minutes,
      :blood_flow_rate,
      :dialysate_flow_rate,
      :target_ultrafiltration,
      :dry_weight,
      :access_type,
      :notes,
      :patient_id,
      :prescribed_by_id
    ])
    |> validate_required([:patient_id, :frequency, :duration_minutes])
  end
end
