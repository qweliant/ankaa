defmodule Ankaa.Community.OrganizationMembership do
  @moduledoc """
  Represents a user's membership in a organization, including their role and status.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ankaa.Accounts.{User}
  alias Ankaa.Community.Organization

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "organization_memberships" do
    field(:role, :string, default: "member")
    field(:status, :string, default: "pending")

    belongs_to(:user, User)
    belongs_to(:organization, Organization)

    timestamps()
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:role, :status, :user_id, :organization_id])
    |> validate_required([:user_id, :organization_id])
    |> validate_inclusion(:role, ["admin", "moderator", "member"])
    |> validate_inclusion(:status, ["active", "banned", "pending"])
    |> unique_constraint([:user_id, :organization_id], name: :unique_user_org_membership)
  end
end
