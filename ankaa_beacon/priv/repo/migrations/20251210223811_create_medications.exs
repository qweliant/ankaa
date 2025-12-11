defmodule Ankaa.Repo.Migrations.CreateMedications do
  use Ecto.Migration

  def change do
    create table(:medications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :strength, :string
      add :frequency, :string
      add :instructions, :text
      add :photo_url, :string
      add :is_active, :boolean, default: true, null: false

      add :patient_id, references(:patients, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:medications, [:patient_id])
  end
end
