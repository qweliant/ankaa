defmodule Ankaa.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions) do
      add(:date, :date)
      add(:duration, :integer)
      add(:notes, :text)
      add(:patient_id, references(:patients, type: :binary_id, on_delete: :delete_all))

      timestamps()
    end

    create(index(:sessions, [:patient_id]))
  end
end
