defmodule Ankaa.Repo.Migrations.AddAlertsTable do
  use Ecto.Migration
  def change do
    create table(:alerts) do
      add :id, :binary_id, primary_key: true
      add :patient_id, references(:users, on_delete: :delete_all)
      add :type, :string
      add :message, :string
      add :acknowledged, :boolean, default: false
      add :resolved_by_id, references(:users, on_delete: :nilify_all)
      timestamps()
    end

    create index(:alerts, [:patient_id])
  end

end
