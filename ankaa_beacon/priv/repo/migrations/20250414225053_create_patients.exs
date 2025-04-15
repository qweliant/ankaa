defmodule Ankaa.Repo.Migrations.CreatePatients do
  use Ecto.Migration

  def change do
    create table(:patients, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:external_id, :string)
      add(:name, :string, null: false)
      add(:date_of_birth, :date)
      add(:timezone, :string)
      add(:device_id, :string)
      add(:user_id, references(:users, type: :binary_id, on_delete: :nothing), null: false)

      timestamps()
    end

    create(unique_index(:patients, [:external_id]))
    create(unique_index(:patients, [:device_id]))
    create(index(:patients, [:user_id]))
  end
end
