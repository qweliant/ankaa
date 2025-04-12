defmodule Ankaa.Accounts.Device do
  use Ecto.Schema
  import Ecto.Changeset

  schema "devices" do
    field(:uuid, :string)
    field(:type, Ecto.Enum, values: [:bp_monitor, :dialysis_machine])
    field(:is_active, :boolean, default: true)
    belongs_to(:user, Ankaa.Accounts.User)

    timestamps()
  end

  def changeset(device, attrs) do
    device
    |> cast(attrs, [:uuid, :type, :is_active, :user_id])
    |> validate_required([:uuid, :type, :user_id])
    |> unique_constraint(:uuid)
    |> foreign_key_constraint(:user_id)
  end
end
