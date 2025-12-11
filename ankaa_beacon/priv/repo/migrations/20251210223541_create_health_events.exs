defmodule Ankaa.Repo.Migrations.CreateHealthEvents do
  use Ecto.Migration

  def change do
    create table(:health_events, primary_key: false) do
    add :id, :binary_id, primary_key: true

    add :type, :string, null: false
    add :category, :string, null: false
    add :data, :map, default: %{}
    add :occurred_at, :utc_datetime, null: false

    add :patient_id, references(:patients, on_delete: :delete_all, type: :binary_id), null: false
    add :logged_by_id, references(:users, on_delete: :nilify_all, type: :binary_id)

    timestamps(type: :utc_datetime)

  end
    create index(:health_events, [:patient_id, :occurred_at])
    create index(:health_events, [:patient_id, :category])
  end
end
