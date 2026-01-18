defmodule Ankaa.Notifications.Message do
  @moduledoc """
  The Messages schema and changeset.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Ankaa.{Accounts.User, Patients.Patient, Notifications.Notification}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field(:content, :string)
    field(:read, :boolean, default: false)
    belongs_to(:sender, User, foreign_key: :sender_id)
    belongs_to(:patient, Patient, foreign_key: :patient_id)
    belongs_to(:recipient, User, foreign_key: :recipient_id)

    has_many(:notifications, Notification,
      foreign_key: :notifiable_id,
      where: [notifiable_type: "Message"]
    )

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :sender_id, :patient_id, :recipient_id, :read])
    |> validate_required([:content, :sender_id])
  end
end
