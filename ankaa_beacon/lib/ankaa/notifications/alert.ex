defmodule Ankaa.Notifications.Alert do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ankaa.{Accounts.User, Patients.Patient}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "alerts" do
    field(:type, :string)
    field(:message, :string)
    field(:acknowledged, :boolean, default: false)

    belongs_to(:patient, Patient, foreign_key: :patient_id)
    belongs_to(:resolved_by, User, foreign_key: :resolved_by_id)

    timestamps()
  end

  def changeset(alert, attrs) do
    alert
    |> cast(attrs, [:type, :message, :patient_id, :acknowledged, :resolved_by_id])
    |> validate_required([:type, :message, :patient_id])
    |> foreign_key_constraint(:resolved_by_id)
    |> foreign_key_constraint(:patient_id)
  end
end
