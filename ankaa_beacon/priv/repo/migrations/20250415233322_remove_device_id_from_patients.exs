defmodule Ankaa.Repo.Migrations.RemoveDeviceIdFromPatients do
  use Ecto.Migration

  def change do
    alter table(:patients) do
      remove(:device_id)
    end
  end
end
