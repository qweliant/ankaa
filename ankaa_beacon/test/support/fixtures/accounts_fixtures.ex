defmodule Ankaa.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ankaa.Accounts` context.
  """

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def valid_user_password, do: "hello world!123"

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: unique_user_email(),
        password: valid_user_password()
      })
      |> Ankaa.Accounts.register_user()

    # If a role was provided in attrs, assign it
    case Map.get(attrs, :role) do
      nil ->
        user

      role ->
        {:ok, user_with_role} = Ankaa.Accounts.assign_role(user, role)
        user_with_role
    end
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
