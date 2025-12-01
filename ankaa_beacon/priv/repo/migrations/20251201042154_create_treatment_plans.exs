defmodule Ankaa.Repo.Migrations.CreateTreatmentPlans do
  use Ecto.Migration

  def change do
    create table(:treatment_plans, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:patient_id, references(:patients, type: :binary_id, on_delete: :delete_all),
        null: false)
      add(:frequency, :string)
      add(:duration_minutes, :integer)
      add(:blood_flow_rate, :integer)
      add(:dialysate_flow_rate, :integer)
      add(:target_ultrafiltration, :float)
      add(:dry_weight, :float)
      add(:access_type, :string)
      add(:notes, :text)
      add(:prescribed_by_id, references(:users, type: :binary_id))

      timestamps()
    end

    create unique_index(:treatment_plans, [:patient_id])
  end
end
