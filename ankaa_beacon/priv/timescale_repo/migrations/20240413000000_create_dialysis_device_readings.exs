defmodule Ankaa.TimescaleRepo.Migrations.CreateDialysisDeviceReadings do
  use Ecto.Migration

  def change do
    create table(:dialysis_device_readings, primary_key: false) do
      add(:device_id, :string, null: false)
      add(:timestamp, :utc_datetime_usec, null: false)

      # Mode and Status
      add(:mode, :string, null: false)
      add(:status, :string, null: false)

      # Time-based metrics
      add(:time_in_alarm, :integer)
      add(:time_in_treatment, :integer)
      add(:time_remaining, :integer)

      # Fluid metrics
      # Dialysate Fluid Volume (L)
      add(:dfv, :float)
      # Dialysate Flow Rate (L/hr)
      add(:dfr, :float)
      # Ultrafiltration Volume (L)
      add(:ufv, :float)
      # Ultrafiltration Rate (L/hr)
      add(:ufr, :float)

      # Blood flow and pressure metrics
      # Blood Flow Rate (ml/min)
      add(:bfr, :integer)
      # Arterial Pressure (mmHg)
      add(:ap, :integer)
      # Venous Pressure (mmHg)
      add(:vp, :integer)
      # Effluent Pressure (mmHg)
      add(:ep, :integer)

      timestamps(type: :utc_datetime_usec)
    end

    # Create hypertable with optimized settings for high-frequency inserts
    execute("""
    SELECT create_hypertable('dialysis_device_readings', 'timestamp',
      chunk_time_interval => INTERVAL '1 hour',
      if_not_exists => TRUE,
      create_default_indexes => FALSE
    );
    """)

    # Create optimized indexes for common query patterns
    execute("""
    CREATE INDEX IF NOT EXISTS dialysis_device_readings_device_id_timestamp_idx
    ON dialysis_device_readings (device_id, timestamp DESC);
    """)

    # Add index for status-based queries
    execute("""
    CREATE INDEX IF NOT EXISTS dialysis_device_readings_status_idx
    ON dialysis_device_readings (status);
    """)

    # Enable compression for older data
    execute("""
    ALTER TABLE dialysis_device_readings SET (
      timescaledb.compress,
      timescaledb.compress_segmentby = 'device_id',
      timescaledb.compress_orderby = 'timestamp DESC'
    );
    """)

    # Set compression policy to compress data older than 7 days
    execute("""
    SELECT add_compression_policy('dialysis_device_readings', INTERVAL '7 days');
    """)
  end
end
