defmodule Ankaa.Repo.Migrations.UpdateRecepientId do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :recipient_id, references(:users, type: :binary_id, on_delete: :nothing)
    end

    create index(:messages, [:recipient_id])
  end
end
