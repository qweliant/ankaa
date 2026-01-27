defmodule Ankaa.Repo.Migrations.ChangeUserToOwner do
  use Ecto.Migration

  def change do
    alter table(:patients) do
      modify :user_id, :binary_id, null: true, from: :binary_id
      add :created_by_user_id, references(:users, type: :binary_id, on_delete: :nilify_all), null: true
    end
  end
end
