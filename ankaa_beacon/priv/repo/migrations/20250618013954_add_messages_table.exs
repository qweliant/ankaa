defmodule Ankaa.Repo.Migrations.AddMessagesTable do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :sender_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :patient_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :content, :text
      add :read, :boolean, default: false
      timestamps()
    end

    create index(:messages, [:patient_id])
  end
end
