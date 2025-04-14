defmodule Ankaa.Repo.Migrations.CreatePatientAssociations do
  use Ecto.Migration

  def change do
    create table(:patient_associations, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:relationship, :string, null: false)
      add(:can_alert, :boolean, default: false)
      add(:user_id, references(:users, type: :binary_id, on_delete: :restrict))
      add(:patient_id, references(:patients, type: :binary_id, on_delete: :restrict))

      timestamps()
    end

    # Create unique index to prevent duplicate associations
    create(
      unique_index(:patient_associations, [:user_id, :patient_id],
        name: :patient_associations_user_id_patient_id_index
      )
    )

    # Create indexes for faster lookups
    create(index(:patient_associations, [:user_id]))
    create(index(:patient_associations, [:patient_id]))
  end
end
