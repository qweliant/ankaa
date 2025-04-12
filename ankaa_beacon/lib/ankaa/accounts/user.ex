defmodule Ankaa.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:email, :string)
    field(:name, :string)
    field(:role, Ecto.Enum, values: [:patient, :caregiver, :doctor])
    field(:phone_number, :string)
    field(:is_active, :boolean, default: true)

    has_many(:devices, Ankaa.Accounts.Device)
    has_many(:alerts, Ankaa.Notifications.Alert, foreign_key: :patient_id)
    has_many(:support_network_as_patient, Ankaa.Accounts.SupportNetwork, foreign_key: :patient_id)

    has_many(:support_network_as_caregiver, Ankaa.Accounts.SupportNetwork,
      foreign_key: :caregiver_id
    )

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :role, :phone_number, :is_active])
    |> validate_required([:email, :name, :role])
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> validate_inclusion(:role, [:patient, :caregiver, :doctor])
  end
end
