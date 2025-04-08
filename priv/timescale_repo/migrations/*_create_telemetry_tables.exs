defmodule Ankaa.TimescaleRepo.Migrations.CreateTelemetryTables do
  use Ecto.Migration

  def up do
    execute("CREATE EXTENSION IF NOT EXISTS timescaledb")

    create table(:bp_device_data) do
      add :device_id, :string, null: false
      add :timestamp, :utc_datetime_usec, null: false
      add :systolic, :float
      add :diastolic, :float
      add :heart_rate, :integer
      add :risk_level, :string

      timestamps()
    end

    create table(:dialysis_device_data) do
      add :device_id, :string, null: false
      add :timestamp, :utc_datetime_usec, null: false
      add :fluid_level, :integer
      add :flow_rate, :integer
      add :clot_detected, :boolean

      timestamps()
    end

    execute("SELECT create_hypertable('bp_device_data', 'timestamp')")
    execute("SELECT create_hypertable('dialysis_device_data', 'timestamp')")
  end

  def down do
    drop table(:bp_device_data)
    drop table(:dialysis_device_data)
  end
end
