defmodule Ankaa.Repo.Migrations.ChangeDeviceIdUniqueness do
  use Ecto.Migration

  def change do
    drop(unique_index(:devices, [:device_id]))

    create(
      unique_index(:devices, [:patient_id, :device_id], name: :devices_patient_id_device_id_index)
    )
  end
end
