defmodule Ankaa.Repo.Migrations.UpdateCareNetworkColumnName do
  use Ecto.Migration

  def up do
    # 1. Create Lookup Tables (Reference Tables)
    create table(:care_network_roles, primary_key: false) do
      add :value, :string, primary_key: true
      add :description, :text
      timestamps()
    end

    create table(:care_network_permissions, primary_key: false) do
      add :value, :string, primary_key: true
      timestamps()
    end

    execute("""
    INSERT INTO care_network_roles (value, description, inserted_at, updated_at) VALUES
      ('admin', 'Generic admin for the patient hub', NOW(), NOW()),
      ('doctor', 'Medical professional', NOW(), NOW()),
      ('nurse', 'Nursing staff', NOW(), NOW()),
      ('caresupport', 'Family member, friend, or caregiver', NOW(), NOW()),
      ('technical_support', 'Device or app technical support', NOW(), NOW()),
      ('tech', 'Dialysis clinic technician', NOW(), NOW()),
      ('social_worker', 'Social worker or case manager', NOW(), NOW()),
      ('patient', 'The patient themselves', NOW(), NOW());
    """)

    execute("""
    INSERT INTO care_network_permissions (value, inserted_at, updated_at) VALUES
      ('owner', NOW(), NOW()),
      ('admin', NOW(), NOW()),
      ('contributor', NOW(), NOW()),
      ('viewer', NOW(), NOW());
    """)

    rename table(:care_network), :role, to: :permission

    alter table(:care_network) do
      add :role, :string
    end

    execute "UPDATE care_network SET role = 'caresupport' WHERE role IS NULL"

    alter table(:care_network) do
      modify :role, references(:care_network_roles, type: :string, column: :value, on_delete: :restrict), null: false

      modify :permission, references(:care_network_permissions, type: :string, column: :value, on_delete: :restrict), null: false
    end
  end

  def down do
    alter table(:care_network) do
      remove :role
      modify :permission, :string
    end

    rename table(:care_network), :permission, to: :role

    drop table(:care_network_roles)
    drop table(:care_network_permissions)
  end
end
