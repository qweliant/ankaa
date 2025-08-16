defmodule Ankaa.Repo.Migrations.DropDeviceIdFromDevices do
  use Ecto.Migration

  def change do
    drop(
      unique_index(:devices, [:patient_id, :device_id], name: :devices_patient_id_device_id_index)
    )

    alter table(:devices) do
      remove(:device_id)
    end
  end
end
