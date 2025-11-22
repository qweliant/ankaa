defmodule Ankaa.Repo.Migrations.CreateMoodTrackers do
  use Ecto.Migration

  def change do
    create table(:mood_trackers, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:mood, :string, null: false)
      add(:symptoms, {:array, :string})
      add(:notes, :text)
      add(:patient_id, references(:patients, type: :binary_id, on_delete: :nothing), null: false)

      timestamps()
    end

    create index(:mood_trackers, [:patient_id, :inserted_at])
  end
end
