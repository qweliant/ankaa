defmodule Ankaa.Community.BoardItem do
  @moduledoc """
  Ecto schema for community board items where users can offer or request items/services.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "community_board_items" do
    field(:type, :string)
    field(:item_name, :string)
    field(:description, :string)
    field(:status, :string, default: "pending")

    belongs_to(:organization, Ankaa.Community.Organization)
    belongs_to(:user, Ankaa.Accounts.User)

    timestamps()
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:type, :item_name, :description, :organization_id, :user_id])
    |> validate_required([:type, :item_name, :organization_id, :user_id])
    |> validate_inclusion(:type, ["offering", "requesting"])
  end

  # Special changeset for the Coordinator to moderate the item
  def moderation_changeset(item, attrs) do
    item
    |> cast(attrs, [:status])
    |> validate_inclusion(:status, ["pending", "approved", "resolved", "rejected"])
  end
end
