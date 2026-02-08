defmodule Ankaa.Community.OrganizationPatient do
  @moduledoc """
  Joins a Patient to an Organization (Clinic).
  Allows the clinic to maintain a roster of patients.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "organization_patients" do
    field :mrn, :string # Medical Record Number specific to this clinic
    field :status, :string, default: "active" # active, discharged, transferred

    belongs_to :organization, Ankaa.Community.Organization
    belongs_to :patient, Ankaa.Patients.Patient

    timestamps()
  end

  def changeset(org_patient, attrs) do
    org_patient
    |> cast(attrs, [:organization_id, :patient_id, :mrn, :status])
    |> validate_required([:organization_id, :patient_id])
    |> unique_constraint([:organization_id, :patient_id], name: :unique_patient_in_org)
  end
end
