defmodule Ankaa.Repo.Migrations.DropInvitesTokenUniqueIndex do
  use Ecto.Migration

  def change do
    drop(unique_index(:invites, [:token], name: :invites_token_index))
  end
end
