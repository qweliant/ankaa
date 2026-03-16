defmodule Ankaa.Repo.Migrations.ChangePatientIdsToUuid do
  use Ecto.Migration

  def up do

    alter table(:sessions) do
      modify :patient_id, :uuid, using: "patient_id::text::uuid"
    end

    alter table(:alerts) do
      modify :patient_id, :uuid, using: "patient_id::text::uuid"
      modify :dismissed_by_user_id, :uuid, using: "dismissed_by_user_id::text::uuid"
      modify :resolved_by_id, :uuid, using: "resolved_by_id::text::uuid"
    end
  end

  def down do
    alter table(:sessions) do
      modify :patient_id, :bigint
    end

    alter table(:alerts) do
      modify :patient_id, :bigint
      modify :dismissed_by_user_id, :bigint
      modify :resolved_by_id, :bigint
    end
  end
end
