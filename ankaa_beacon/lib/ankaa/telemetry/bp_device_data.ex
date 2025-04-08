defmodule Ankaa.Telemetry.BPDeviceData do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bp_device_data" do
    field :device_id, :string
    field :timestamp, :utc_datetime_usec
    field :systolic, :float
    field :diastolic, :float
    field :heart_rate, :integer
    field :risk_level, :string

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:device_id, :timestamp, :systolic, :diastolic, :heart_rate, :risk_level])
    |> validate_required([:device_id, :timestamp])
  end
end
