defmodule Ankaa.Community.Organization do
  @moduledoc """
  Represents a healthcare organization.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "organizations" do
    field(:name, :string)
    field(:npi_number, :string)
    field(:type, :string)
    field(:description, :string)
    field(:is_public, :boolean, default: true)

    has_many(:memberships, Ankaa.Community.OrganizationMembership)
    has_many(:members, through: [:memberships, :user])
    timestamps()
  end

  def changeset(org, attrs) do
    org
    |> cast(attrs, [:name, :npi_number, :type])
    |> validate_required([:name])
  end
end
