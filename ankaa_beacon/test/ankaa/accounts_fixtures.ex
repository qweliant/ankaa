defmodule Ankaa.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ankaa.Accounts` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: unique_user_email(),
        password: "some password"
      })
      |> Ankaa.Accounts.register_user()

    user
  end

  @doc """
  Generate a unique user email.
  """
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: unique_user_email(),
        password: "some password"
      })
      |> Ankaa.Accounts.register_user()

    user
  end

  @doc """
  Generate a user token.
  """
  def user_token_fixture(attrs \\ %{}) do
    {:ok, token} =
      attrs
      |> Enum.into(%{
        context: "some context",
        sent_to: "some@email.com",
        token: "some token"
      })
      |> Ankaa.Accounts.create_user_token()

    token
  end
end
