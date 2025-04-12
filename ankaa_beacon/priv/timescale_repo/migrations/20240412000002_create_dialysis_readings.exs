defmodule Ankaa.TimescaleRepo.Migrations.CreateDialysisReadings do
  use Ecto.Migration

  def up do
    create table(:dialysis_readings, primary_key: false) do
      add(:id, :uuid, null: false)  # Not a primary key anymore
      add(:device_id, :string, null: false)
      add(:timestamp, :timestamptz, null: false)
      add(:fluid_level, :integer, null: false)
      add(:flow_rate, :integer, null: false)
      add(:clot_detected, :boolean)
      add(:patient_id, :uuid, null: false)

      timestamps()
    end

    # Create a composite primary key
    execute("ALTER TABLE dialysis_readings ADD PRIMARY KEY (id, timestamp);")

    # Create hypertable for time-series data
    execute("""
    SELECT create_hypertable('dialysis_readings', 'timestamp',
      chunk_time_interval => INTERVAL '1 day',
      if_not_exists => TRUE
    );
    """)

    # Create indexes for efficient querying
    create(index(:dialysis_readings, [:device_id]))
    create(index(:dialysis_readings, [:patient_id]))
    create(index(:dialysis_readings, [:clot_detected]))
    # No need for timestamp index as it's part of the primary key
  end

  def down do
    drop(table(:dialysis_readings))
  end
end
