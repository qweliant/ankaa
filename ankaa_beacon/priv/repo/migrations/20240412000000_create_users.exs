defmodule Ankaa.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:email, :string, null: false)
      add(:password_hash, :string, null: false)
      add(:role, :string, null: false)
      add(:device_id, :string)
      add(:name, :string)

      timestamps()
    end

    create(unique_index(:users, [:email]))
    create(unique_index(:users, [:device_id]))
  end
end
