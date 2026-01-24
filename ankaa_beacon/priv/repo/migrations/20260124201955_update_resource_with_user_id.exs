defmodule Ankaa.Repo.Migrations.UpdateResourceWithUserId do
  use Ecto.Migration

def change do
    alter table(:community_resources) do
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:community_resources, [:user_id])
  end
end
