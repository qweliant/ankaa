defmodule Ankaa.Repo.Migrations.CreateReadings do
  use Ecto.Migration

  def change do
    create table(:readings, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:device_id, :binary_id, null: false)
      add(:payload, :map, null: false)
      add(:recorded_at, :utc_datetime, null: false)
      add(:patient_id, references(:patients, on_delete: :delete_all, type: :binary_id))

      timestamps()
    end

    create(index(:readings, [:device_id]))
    create(index(:readings, [:patient_id]))
  end
end
