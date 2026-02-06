defmodule Ankaa.Repo.Migrations.DropRoleFkeyFromCareNetwork do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE care_network DROP CONSTRAINT care_network_role_fkey"
  end
end
