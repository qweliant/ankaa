defmodule Ankaa.Repo.Migrations.AddDismissalFieldsToAlerts do
  use Ecto.Migration

  def change do
    alter table(:alerts) do
      add(:status, :string, default: "active", null: false)
      add(:dismissed_at, :utc_datetime)
      add(:dismissed_by_user_id, references(:users, type: :binary_id))
      add(:dismissal_reason, :string)
    end
  end
end
