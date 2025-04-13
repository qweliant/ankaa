defmodule Ankaa.TimescaleRepo.Migrations.CreateBloodPressureDeviceReadings do
  use Ecto.Migration

  def change do
    create table(:blood_pressure_device_readings, primary_key: false) do
      add(:device_id, :string, null: false)
      add(:timestamp, :utc_datetime_usec, null: false)

      # Mode and Status
      add(:mode, :string, null: false)
      add(:status, :string, null: false)

      # Blood pressure metrics
      add(:systolic, :integer, null: false)
      add(:diastolic, :integer, null: false)
      add(:heart_rate, :integer, null: false)

      # Additional metrics
      add(:mean_arterial_pressure, :integer)
      add(:pulse_pressure, :integer)
      add(:irregular_heartbeat, :boolean, default: false)

      timestamps(type: :utc_datetime_usec)
    end

    # Create hypertable with optimized settings for high-frequency inserts
    execute("""
    SELECT create_hypertable('blood_pressure_device_readings', 'timestamp',
      chunk_time_interval => INTERVAL '1 hour',
      if_not_exists => TRUE,
      create_default_indexes => FALSE
    );
    """)

    # Create optimized indexes for common query patterns
    execute("""
    CREATE INDEX IF NOT EXISTS blood_pressure_device_readings_device_id_timestamp_idx
    ON blood_pressure_device_readings (device_id, timestamp DESC);
    """)

    # Add index for status-based queries
    execute("""
    CREATE INDEX IF NOT EXISTS blood_pressure_device_readings_status_idx
    ON blood_pressure_device_readings (status);
    """)

    # Enable compression for older data
    execute("""
    ALTER TABLE blood_pressure_device_readings SET (
      timescaledb.compress,
      timescaledb.compress_segmentby = 'device_id',
      timescaledb.compress_orderby = 'timestamp DESC'
    );
    """)

    # Set compression policy to compress data older than 7 days
    execute("""
    SELECT add_compression_policy('blood_pressure_device_readings', INTERVAL '7 days');
    """)
  end
end
