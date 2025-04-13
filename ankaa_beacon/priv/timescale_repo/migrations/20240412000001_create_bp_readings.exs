defmodule Ankaa.TimescaleRepo.Migrations.CreateBPReadings do
  use Ecto.Migration

  def up do
    execute("DROP TABLE IF EXISTS bp_readings;")
    create table(:bp_readings, primary_key: false) do
      # Not a primary key anymore
      add(:id, :uuid, null: false)
      add(:device_id, :string, null: false)
      add(:patient_id, :uuid, null: false)
      add(:timestamp, :utc_datetime_usec, null: false)
      add(:systolic, :float, null: false)
      add(:diastolic, :float, null: false)
      add(:heart_rate, :integer, null: false)
      add(:risk_level, :string, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    # Create a composite primary key
    execute("ALTER TABLE bp_readings ADD PRIMARY KEY (id, timestamp);")

    # Create hypertable for time-series data
    execute("""
    SELECT create_hypertable('bp_readings', 'timestamp',
      chunk_time_interval => INTERVAL '1 day',
      if_not_exists => TRUE
    );
    """)

    # Create indexes for efficient querying
    create(index(:bp_readings, [:device_id]))
    create(index(:bp_readings, [:patient_id]))
    create(index(:bp_readings, [:risk_level]))
    # No need for timestamp index as it's part of the primary key
  end

  def down do
    drop(table(:bp_readings))
  end
end
