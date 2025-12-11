defmodule Ankaa.Repo.Migrations.CreateAppointments do
  use Ecto.Migration

  def change do
    create table(:appointments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :provider_name, :string
      add :start_time, :utc_datetime, null: false
      add :end_time, :utc_datetime
      add :is_all_day, :boolean, default: false

      add :location_name, :string
      add :address, :string
      add :notes, :text

      add :patient_id, references(:patients, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:appointments, [:patient_id, :start_time])
  end
end
