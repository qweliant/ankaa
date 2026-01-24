defmodule Ankaa.Community.Resource do
  @moduledoc """
  Ecto schema for community resources such as articles, videos, and external links.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "community_resources" do
    field(:title, :string)
    field(:description, :string)
    field(:url, :string)
    field(:category, :string)

    belongs_to :organization, Ankaa.Community.Organization
    belongs_to :user, Ankaa.Accounts.User

    timestamps()
  end

  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [:title, :description, :url, :category, :organization_id, :user_id])
    |> validate_required([:title, :url, :category, :organization_id, :user_id])
  end
end
