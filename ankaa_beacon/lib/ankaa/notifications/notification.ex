defmodule Ankaa.Notifications.Notification do
  @moduledoc """
  Ecto schema for user notifications and related changesets.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Ankaa.Accounts.User
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @statuses ["unread", "read", "dismissed", "acknowledged"]
  schema "notifications" do
    field(:status, :string, default: "unread")
    belongs_to(:user, User, type: :binary_id, foreign_key: :user_id)
    field(:notifiable_id, :binary_id)
    field(:notifiable_type, :string)
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:user_id, :status, :notifiable_id, :notifiable_type])
    |> validate_required([:user_id, :status, :notifiable_id, :notifiable_type])
    |> validate_inclusion(:status, @statuses)
  end
end
