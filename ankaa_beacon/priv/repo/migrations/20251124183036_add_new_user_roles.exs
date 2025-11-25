defmodule Ankaa.Repo.Migrations.AddNewUserRoles do
  use Ecto.Migration

  def up do
    # 1. Clinic Technician
    execute("""
    INSERT INTO user_roles (value, description, inserted_at, updated_at)
    VALUES ('clinic_technician', 'Proactive triage and patient caseload management', NOW(), NOW())
    """)

    # 2. Community Coordinator
    execute("""
    INSERT INTO user_roles (value, description, inserted_at, updated_at)
    VALUES ('community_coordinator', 'Manages patient support groups and resources', NOW(), NOW())
    """)

    # 3. Social Worker
    execute("""
    INSERT INTO user_roles (value, description, inserted_at, updated_at)
    VALUES ('social_worker', 'Provides psychosocial support and non-medical resource coordination', NOW(), NOW())
    """)
  end

  def down do
    # Remove the new roles
    execute(
      "DELETE FROM user_roles WHERE value IN ('clinic_technician', 'community_coordinator', 'social_worker')"
    )
  end
end
