defmodule Ankaa.Repo.Migrations.CreateIncidents do
  use Ecto.Migration

  def change do
    create table(:incidents, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:patient_id, references(:patients, type: :binary_id, on_delete: :nothing))
      add(:alert_id, references(:alerts, type: :binary_id, on_delete: :nothing))

      add(:trigger_time, :utc_datetime)
      add(:trigger_reason, :string)
      add(:vital_snapshot, :map)
      add(:dispatch_id, :string)
      add(:status, :string)

      timestamps()
    end
    create index(:incidents, [:patient_id])
  end
end
