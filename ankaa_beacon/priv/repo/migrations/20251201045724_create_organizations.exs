defmodule Ankaa.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration

  def change do
    create table(:organizations, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string, null: false)
      add(:npi_number, :string)
      add(:type, :string)

      timestamps()
    end

    alter table(:users) do
      add :organization_id, references(:organizations, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:users, [:organization_id])
  end
end
