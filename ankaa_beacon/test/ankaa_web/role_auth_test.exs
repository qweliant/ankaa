defmodule AnkaaWeb.RoleAuthTest do
  use AnkaaWeb.ConnCase, async: true

  alias Phoenix.LiveView
  alias Ankaa.Accounts
  alias AnkaaWeb.RoleAuth
  import Ankaa.AccountsFixtures

  setup %{conn: conn} do
    %{user: user_fixture(), conn: conn}
  end

  describe "Role-based access control" do
    test "creating a new role", %{user: user} do
      role_attrs = %{value: "new_role", description: "A new role for testing"}
      {:ok, role} = Accounts.create_user_role(role_attrs)

      assert role.value == "new_role"
      assert role.description == "A new role for testing"
    end

    test "assigning a role to a user", %{user: user} do
      role = "nurse"
      {:ok, updated_user} = Accounts.assign_role(user, role)
      assert Accounts.has_role?(updated_user, "nurse")
    end

    test "validating user role access", %{user: user} do
      roles = ["doctor", "nurse", "admin", "caregiver", "technical_support"]

      for role <- roles do
        {:ok, updated_user} = Accounts.assign_role(user, role)
        assert Accounts.has_role?(updated_user, role)
      end

      refute Accounts.has_role?(user, "non_existent_role")
    end

    test "role checking functions", %{user: user} do
      role = "admin"
      {:ok, updated_user} = Accounts.assign_role(user, role)

      assert Accounts.is_admin?(updated_user)
      refute Accounts.is_doctor?(updated_user)
      refute Accounts.is_nurse?(updated_user)
    end
  end

  # describe "on_mount callbacks" do
  #   test "allows access for authorized roles", %{conn: conn, user: user} do
  #     {:ok, updated_user} = Accounts.assign_role(user, "doctor")
  #     session = conn |> put_session(:user_token, Accounts.generate_user_session_token(updated_user)) |> get_session()

  #     {:cont, socket} = RoleAuth.on_mount(:require_doctor, %{}, session, %LiveView.Socket{})
  #     assert socket.assigns.current_user.id == user.id
  #   end

  #   test "redirects unauthorized users", %{conn: conn, user: user} do
  #     session = conn |> put_session(:user_token, Accounts.generate_user_session_token(user)) |> get_session()

  #     {:halt, socket} = RoleAuth.on_mount(:require_admin, %{}, session, %LiveView.Socket{})
  #     assert socket.redirected_to == "/"
  #     assert Phoenix.Flash.get(socket.assigns.flash, :error) == "You are not authorized to access this page."
  #   end
  # end
end
