defmodule Ankaa.Repo.Migrations.AddNameToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:first_name, :string)
      add(:last_name, :string)
    end
  end
end
