defmodule Ankaa.Accounts.Organization do
  @moduledoc """
  Represents a healthcare organization.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ankaa.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "organizations" do
    field(:name, :string)
    field(:npi_number, :string)
    field(:type, :string)

    has_many(:users, User)

    timestamps()
  end

  def changeset(org, attrs) do
    org
    |> cast(attrs, [:name, :npi_number, :type])
    |> validate_required([:name])
  end
end
