defmodule Ankaa.Repo.Migrations.CreateDevices do
  use Ecto.Migration

  def change do
    create table(:devices, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:type, :string, null: false)
      add(:model, :string)
      add(:device_id, :string, null: false)

      add(:patient_id, references(:patients, type: :binary_id, on_delete: :delete_all),
        null: false
      )

      timestamps()
    end

    create(unique_index(:devices, [:device_id]))
    create(index(:devices, [:patient_id]))
  end
end
