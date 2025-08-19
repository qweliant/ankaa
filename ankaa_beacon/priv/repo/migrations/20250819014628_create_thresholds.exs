defmodule Ankaa.Repo.Migrations.CreateThresholds do
  use Ecto.Migration

  def change do
    create table(:thresholds, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:device_type, :string, null: false)
      add(:parameter, :string, null: false)
      add(:min_value, :float)
      add(:max_value, :float)
      add(:severity, :string, null: false)
      add(:patient_id, references(:patients, on_delete: :delete_all, type: :binary_id))

      timestamps()
    end

    create(index(:thresholds, [:patient_id, :device_type]))
  end
end
