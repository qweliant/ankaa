defmodule Ankaa.Communication.Message do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ankaa.{Accounts.User, Patients.Patient}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field(:content, :string)
    field(:read, :boolean, default: false)
    belongs_to(:sender, User, foreign_key: :user_id)
    belongs_to(:patient, Patient, foreign_key: :patient_id)
    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :sender_id, :patient_id])
    |> validate_required([:content, :sender_id, :patient_id])
  end
end
