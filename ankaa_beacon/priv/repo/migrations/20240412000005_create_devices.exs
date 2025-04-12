defmodule Ankaa.Repo.Migrations.CreateDevices do
  use Ecto.Migration

  def change do
    create table(:devices) do
      add(:uuid, :string, null: false)
      add(:type, :string, null: false)
      add(:is_active, :boolean, default: true)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:devices, [:uuid]))
    create(index(:devices, [:user_id]))
    create(index(:devices, [:type]))
  end
end
