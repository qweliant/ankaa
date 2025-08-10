defmodule Ankaa.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ankaa.Accounts.User
  alias Ankaa.Notifications.Alert
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @statuses ["unread", "read", "dismissed", "acknowledged"]
  schema "notifications" do
    field(:status, :string, default: "unread")
    belongs_to(:user, User, type: :binary_id, foreign_key: :user_id)
    belongs_to(:alert, Alert, type: :binary_id, foreign_key: :alert_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:user_id, :alert_id, :status])
    |> validate_required([:user_id, :alert_id, :status])
    |> validate_inclusion(:status, @statuses)
  end
end
