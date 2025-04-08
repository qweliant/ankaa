defmodule Ankaa.Telemetry.DialysisDeviceData do
  use Ecto.Schema
  import Ecto.Changeset

  schema "dialysis_device_data" do
    field :device_id, :string
    field :timestamp, :utc_datetime_usec
    field :fluid_level, :integer
    field :flow_rate, :integer
    field :clot_detected, :boolean

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:device_id, :timestamp, :fluid_level, :flow_rate, :clot_detected])
    |> validate_required([:device_id, :timestamp])
  end
end
