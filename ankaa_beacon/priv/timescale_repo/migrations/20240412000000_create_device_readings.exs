defmodule Ankaa.TimescaleRepo.Migrations.CreateDeviceReadings do
  use Ecto.Migration

  def up do
    create table(:device_readings, primary_key: false) do
      # Not a primary key anymore
      add(:id, :uuid, null: false)
      add(:device_id, :string, null: false)
      add(:patient_id, :uuid, null: false)
      add(:timestamp, :utc_datetime_usec, null: false)
      add(:type, :string, null: false)
      add(:value, :float, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    # Create a composite primary key
    execute("ALTER TABLE device_readings ADD PRIMARY KEY (id, timestamp);")

    # Create hypertable for time-series data
    execute("""
    SELECT create_hypertable('device_readings', 'timestamp',
      chunk_time_interval => INTERVAL '1 day',
      if_not_exists => TRUE
    );
    """)

    # Create indexes for efficient querying
    create(index(:device_readings, [:device_id]))
    create(index(:device_readings, [:patient_id]))
    # No need for timestamp index as it's part of the primary key
  end

  def down do
    drop(table(:device_readings))
  end
end
