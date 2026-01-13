defmodule Ankaa.Repo.Migrations.UpdateRoleForCareNetwork do
  use Ecto.Migration

  def change do
    alter table(:care_network) do
      remove :permissions
      add :role, :string, null: false, default: "viewer"
    end

    create constraint(:care_network, :role_must_be_valid, check: "role IN ('owner','admin','contributor','viewer')")
  end
end
