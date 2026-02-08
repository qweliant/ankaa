defmodule Ankaa.Repo.Migrations.CreateOrganizationPatient do
  use Ecto.Migration

  def change do
  create table(:organization_patients, primary_key: false) do
    add :id, :binary_id, primary_key: true
    add :mrn, :string
    add :status, :string, default: "active"
    add :organization_id, references(:organizations, on_delete: :delete_all, type: :binary_id), null: false
    add :patient_id, references(:patients, on_delete: :delete_all, type: :binary_id), null: false

    timestamps()
  end

  create unique_index(:organization_patients, [:organization_id, :patient_id], name: :unique_patient_in_org)
  create unique_index(:organization_patients, [:organization_id, :mrn])
  end
end
