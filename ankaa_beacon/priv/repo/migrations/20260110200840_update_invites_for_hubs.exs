defmodule Ankaa.Repo.Migrations.UpdateInvitesForHubs do
  use Ecto.Migration

  def change do
    alter table(:invites) do
      modify :organization_id, :binary_id, null: true
      add :invitee_permission, :string, null: true
    end
  end
end
