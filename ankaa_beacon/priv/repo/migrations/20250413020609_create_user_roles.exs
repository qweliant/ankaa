defmodule Ankaa.Repo.Migrations.CreateUserRoles do
  use Ecto.Migration

  def change do
    create table(:user_roles, primary_key: false) do
      add(:value, :string, primary_key: true)
      add(:description, :text, default: "")
      timestamps()
    end

    # Insert the standard roles
    execute("""
    INSERT INTO user_roles (value, description, inserted_at, updated_at)
    VALUES
      ('doctor', 'Medical professional with full patient access', NOW(), NOW()),
      ('nurse', 'Nursing staff with patient care access', NOW(), NOW()),
      ('caresupport', 'Family member or friend providing care', NOW(), NOW()),
      ('tech', 'Technical support staff for device issues', NOW(), NOW()),
      ('admin', 'System administrator', NOW(), NOW());
    """)

    # Add role to users table
    alter table(:users) do
      add(:role, references(:user_roles, type: :string, column: :value, on_delete: :restrict))
    end

    # Create index for faster lookups
    create(index(:users, [:role]))
  end
end
