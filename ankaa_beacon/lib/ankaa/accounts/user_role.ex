defmodule Ankaa.Accounts.UserRole do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:value, :string, autogenerate: false}
  schema "user_roles" do
    field(:description, :string)
    timestamps()
  end

  def changeset(user_role, attrs) do
    user_role
    |> cast(attrs, [:value, :description])
    |> validate_required([:value, :description])
    |> unique_constraint(:value)
  end
end
