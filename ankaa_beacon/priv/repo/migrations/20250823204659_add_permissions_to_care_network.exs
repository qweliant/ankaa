defmodule Ankaa.Repo.Migrations.AddPermissionsToCareNetwork do
  use Ecto.Migration

  def change do
    alter table(:care_network) do
      add(:permissions, {:array, :string}, default: [], null: false)
      remove(:can_alert)
    end
  end
end
