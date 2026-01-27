defmodule Ankaa.Repo.Migrations.AddInviteeRelationship do
  use Ecto.Migration

  def change do
    alter table(:invites) do
      add :invitee_relationship, :string
    end
  end
end
