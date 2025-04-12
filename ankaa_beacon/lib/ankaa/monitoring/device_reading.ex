defmodule Ankaa.Monitoring.DeviceReading do
  use Ecto.Schema
  import Ecto.Changeset

  @foreign_key_type :binary_id
  schema "device_readings" do
    field(:device_id, :string)
    field(:timestamp, :utc_datetime_usec)
    field(:patient_id, :binary_id)

    timestamps()
  end

  def changeset(reading, attrs) do
    reading
    |> cast(attrs, [:device_id, :timestamp, :patient_id])
    |> validate_required([:device_id, :timestamp])
  end

  @moduledoc """
  Parent module for all device readings with common functions
  """

  @callback from_mqtt(map()) :: struct()
  @callback check_thresholds(struct()) :: [Ankaa.Monitoring.ThresholdViolation.t()]
end
