defmodule Ankaa.Repo.Migrations.CreateOrganizationMemberships do
  use Ecto.Migration

  def change do
    create table(:organization_memberships, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :organization_id, references(:organizations, on_delete: :delete_all, type: :binary_id), null: false
      add :role, :string, null: false, default: "member"
      add :status, :string, null: false, default: "pending"
      timestamps()
    end

    create unique_index(:organization_memberships, [:user_id, :organization_id], name: :unique_user_org_membership)
    create index(:organization_memberships, [:organization_id])
    create index(:organization_memberships, [:user_id])

    create constraint(:organization_memberships, :role_must_be_valid, check: "role IN ('admin','moderator','member')")
    create constraint(:organization_memberships, :status_must_be_valid, check: "status IN ('active','banned','pending')")

    alter table(:users) do
      remove :organization_id
    end

    alter table(:organizations) do
      add :description, :string
      add :is_public, :boolean, default: true
    end
  end
end
