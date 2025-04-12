defmodule Ankaa.Repo.Migrations.CreateSupportNetwork do
  use Ecto.Migration

  def change do
    create table(:support_network) do
      add(:relationship_type, :string, null: false)
      add(:can_receive_alerts, :boolean, default: false)
      add(:is_available_for_emergency, :boolean, default: false)
      add(:patient_id, references(:users, on_delete: :delete_all), null: false)
      add(:caregiver_id, references(:users, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(
      unique_index(:support_network, [:patient_id, :caregiver_id], name: :unique_relationship)
    )

    create(index(:support_network, [:patient_id]))
    create(index(:support_network, [:caregiver_id]))
    create(index(:support_network, [:relationship_type]))
    create(index(:support_network, [:is_available_for_emergency]))
  end
end
