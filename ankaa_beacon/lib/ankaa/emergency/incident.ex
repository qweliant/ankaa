defmodule Ankaa.Emergency.Incident do
  @moduledoc """
  Ecto schema representing an emergency incident.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "incidents" do
    field(:trigger_time, :utc_datetime)
    field(:trigger_reason, :string)
    field(:vital_snapshot, :map)
    field(:dispatch_id, :string)
    field(:status, :string)

    belongs_to :patient, Ankaa.Patients.Patient
    belongs_to :alert, Ankaa.Notifications.Alert

    timestamps()
  end

  def changeset(incident, attrs) do
    incident
    |> cast(attrs, [
      :trigger_time,
      :trigger_reason,
      :vital_snapshot,
      :dispatch_id,
      :status,
      :patient_id,
      :alert_id
    ])
    |> validate_required([:trigger_time, :trigger_reason, :patient_id, :status])
  end
end
