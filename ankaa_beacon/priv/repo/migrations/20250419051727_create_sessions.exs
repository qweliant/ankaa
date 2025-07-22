defmodule Ankaa.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions) do
      add(:start_time, :utc_datetime, null: false)
      add(:end_time, :utc_datetime)
      add(:status, :string, null: false, default: "ongoing")

      add(:notes, :string)

      add(:patient_id, references(:patients, type: :binary_id, on_delete: :delete_all))

      timestamps()
    end

    create(index(:sessions, [:patient_id]))
  end
end
