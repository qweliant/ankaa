defmodule Ankaa.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ankaa.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Ankaa.Accounts.register_user()

    user
  end

  def user_token_fixture(user) do
    {:ok, token, _claims} = Ankaa.Accounts.generate_user_session_token(user)
    token
  end

  def extract_user_token(fun) do
    {:ok, captured} = fun.()
    captured
  end
end
