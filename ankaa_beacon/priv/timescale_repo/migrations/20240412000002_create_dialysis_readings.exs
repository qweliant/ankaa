defmodule Ankaa.TimescaleRepo.Migrations.CreateDialysisReadings do
  use Ecto.Migration

  def up do
    create table(:dialysis_readings, primary_key: false) do
      add(:id, :uuid, null: false)
      add(:device_id, :string, null: false)
      add(:timestamp, :utc_datetime_usec, null: false)
      add(:mode, :string, null: false)
      add(:status, :string, null: false)
      add(:time_in_alarm, :integer)
      add(:time_in_treatment, :integer)
      add(:time_remaining, :integer)
      # Dialysate Fluid Volume (L)
      add(:dfv, :float)
      # Dialysate Flow Rate (L/hr)
      add(:dfr, :float)
      # Ultrafiltration Volume (L)
      add(:ufv, :float)
      # Ultrafiltration Rate (L/hr)
      add(:ufr, :float)
      # Blood Flow Rate (ml/min)
      add(:bfr, :integer)
      # Arterial Pressure (mmHg)
      add(:ap, :integer)
      # Venous Pressure (mmHg)
      add(:vp, :integer)
      # Effluent Pressure (mmHg)
      add(:ep, :integer)
      add(:patient_id, :uuid, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    execute("""
    ALTER TABLE dialysis_readings ADD PRIMARY KEY (id, timestamp);
    """)

    execute("""
    SELECT create_hypertable('dialysis_readings', 'timestamp',
      chunk_time_interval => INTERVAL '1 day',
      if_not_exists => TRUE
    );
    """)

    create(index(:dialysis_readings, [:device_id]))
    create(index(:dialysis_readings, [:patient_id]))
    create(index(:dialysis_readings, [:status]))
    create(index(:dialysis_readings, [:mode]))
    create(index(:dialysis_readings, [:bfr]))
    create(index(:dialysis_readings, [:vp]))
  end

  def down do
    drop(table(:dialysis_readings))
  end
end
