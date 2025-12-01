defmodule Ankaa.Repo.Migrations.AddOrganizationToInvites do
  use Ecto.Migration

  def change do
    alter table(:invites) do
      add(:organization_id, references(:organizations, type: :binary_id, on_delete: :nilify_all))
    end

    create index(:invites, [:organization_id])
  end
end
