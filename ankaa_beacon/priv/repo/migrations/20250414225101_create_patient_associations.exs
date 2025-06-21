defmodule Ankaa.Repo.Migrations.CreatePatientAssociations do
  use Ecto.Migration

  def change do
    create table(:care_network, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:relationship, :string, null: false)
      add(:can_alert, :boolean, default: false, null: false)
      add(:user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false)

      add(:patient_id, references(:patients, type: :binary_id, on_delete: :delete_all),
        null: false
      )

      timestamps()
    end

    create(index(:care_network, [:user_id]))
    create(index(:care_network, [:patient_id]))

    create(
      unique_index(:care_network, [:user_id, :patient_id],
        name: :patient_associations_user_id_patient_id_index
      )
    )
  end
end
