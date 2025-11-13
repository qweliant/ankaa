defmodule Ankaa.Repo.Migrations.MakeNotificationsPolymorphic do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      remove(:alert_id, :binary_id)
      add(:notifiable_id, :binary_id, null: false)
      add(:notifiable_type, :string, null: false)
    end

    create(index(:notifications, [:notifiable_id, :notifiable_type]))
  end
end
