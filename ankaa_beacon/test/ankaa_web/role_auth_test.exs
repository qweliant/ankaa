defmodule AnkaaWeb.RoleAuthTest do
  use AnkaaWeb.ConnCase, async: true
  import Ankaa.AccountsFixtures

  alias Phoenix.LiveView
  alias Ankaa.Accounts
  alias AnkaaWeb.RoleAuth
  alias Ankaa.Patients

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, AnkaaWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{user: user_fixture(), conn: conn}
  end

  describe "on_mount :require_doctor" do
    test "allows access for doctor roles", %{conn: conn, user: user} do
      {:ok, updated_user} = Accounts.assign_role(user, "doctor")
      user_token = Accounts.generate_user_session_token(updated_user)
      session = conn |> put_session(:user_token, user_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: AnkaaWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, session: session}
      }

      {:cont, socket} = RoleAuth.on_mount(:require_doctor, %{}, session, socket)
      assert socket.assigns.current_user.id == user.id
      assert socket.assigns.current_user.role == "doctor"
    end

    test "redirects unauthorized users", %{conn: conn, user: user} do
      user_token = Accounts.generate_user_session_token(user)
      session = conn |> put_session(:user_token, user_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: AnkaaWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, socket} = RoleAuth.on_mount(:require_doctor, %{}, session, socket)
      assert socket.redirected == {:redirect, %{to: "/", status: 302}}

      assert Phoenix.Flash.get(socket.assigns.flash, :error) ==
               "You are not authorized to access this page."
    end
  end

  describe "on_mount :require_nurse" do
    test "allows access for nurse roles", %{conn: conn, user: user} do
      {:ok, updated_user} = Accounts.assign_role(user, "nurse")
      user_token = Accounts.generate_user_session_token(updated_user)
      session = conn |> put_session(:user_token, user_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: AnkaaWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, session: session}
      }

      {:cont, socket} = RoleAuth.on_mount(:require_nurse, %{}, session, socket)
      assert socket.assigns.current_user.id == user.id
      assert socket.assigns.current_user.role == "nurse"
    end

    test "redirects unauthorized users", %{conn: conn, user: user} do
      user_token = Accounts.generate_user_session_token(user)
      session = conn |> put_session(:user_token, user_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: AnkaaWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, socket} = RoleAuth.on_mount(:require_nurse, %{}, session, socket)
      assert socket.redirected == {:redirect, %{to: "/", status: 302}}

      assert Phoenix.Flash.get(socket.assigns.flash, :error) ==
               "You are not authorized to access this page."
    end
  end

  describe "on_mount :require_doctor_or_nurse" do
    test "allows access for doctor or nurse roles", %{conn: conn, user: user} do
      {:ok, updated_user} = Accounts.assign_role(user, "doctor")
      user_token = Accounts.generate_user_session_token(updated_user)
      session = conn |> put_session(:user_token, user_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: AnkaaWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, session: session}
      }

      {:cont, socket} = RoleAuth.on_mount(:require_doctor_or_nurse, %{}, session, socket)
      assert socket.assigns.current_user.id == user.id
      assert socket.assigns.current_user.role == "doctor"
    end

    test "redirects unauthorized users", %{conn: conn, user: user} do
      user_token = Accounts.generate_user_session_token(user)
      session = conn |> put_session(:user_token, user_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: AnkaaWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, socket} = RoleAuth.on_mount(:require_doctor_or_nurse, %{}, session, socket)
      assert socket.redirected == {:redirect, %{to: "/", status: 302}}

      assert Phoenix.Flash.get(socket.assigns.flash, :error) ==
               "You are not authorized to access this page."
    end
  end

  describe "on_mount :require_caresupport" do
    test "allows access for caresupport roles", %{conn: conn, user: user} do
      {:ok, updated_user} = Accounts.assign_role(user, "caresupport")
      user_token = Accounts.generate_user_session_token(updated_user)
      session = conn |> put_session(:user_token, user_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: AnkaaWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, session: session}
      }

      {:cont, socket} = RoleAuth.on_mount(:require_caresupport, %{}, session, socket)
      assert socket.assigns.current_user.id == user.id
      assert socket.assigns.current_user.role == "caresupport"
    end

    test "redirects unauthorized users", %{conn: conn, user: user} do
      user_token = Accounts.generate_user_session_token(user)
      session = conn |> put_session(:user_token, user_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: AnkaaWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, socket} = RoleAuth.on_mount(:require_caresupport, %{}, session, socket)
      assert socket.redirected == {:redirect, %{to: "/", status: 302}}

      assert Phoenix.Flash.get(socket.assigns.flash, :error) ==
               "You are not authorized to access this page."
    end
  end

  describe "on_mount :require_technical_support" do
    test "allows access for technical support roles", %{conn: conn, user: user} do
      {:ok, updated_user} = Accounts.assign_role(user, "technical_support")
      user_token = Accounts.generate_user_session_token(updated_user)
      session = conn |> put_session(:user_token, user_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: AnkaaWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, session: session}
      }

      {:cont, socket} = RoleAuth.on_mount(:require_technical_support, %{}, session, socket)
      assert socket.assigns.current_user.id == user.id
      assert socket.assigns.current_user.role == "technical_support"
    end

    test "redirects unauthorized users", %{conn: conn, user: user} do
      user_token = Accounts.generate_user_session_token(user)
      session = conn |> put_session(:user_token, user_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: AnkaaWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, socket} = RoleAuth.on_mount(:require_technical_support, %{}, session, socket)
      assert socket.redirected == {:redirect, %{to: "/", status: 302}}

      assert Phoenix.Flash.get(socket.assigns.flash, :error) ==
               "You are not authorized to access this page."
    end
  end

  describe "on_mount :require_patient" do
    test "allows access for patient roles", %{conn: conn, user: user} do
      attrs = %{name: "Harold Melvin", user_id: user.id}
      {:ok, _patient} = Patients.create_patient(attrs, user)
      user_token = Accounts.generate_user_session_token(user)
      session = conn |> put_session(:user_token, user_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: AnkaaWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}, session: session}
      }

      {:cont, socket} = RoleAuth.on_mount(:require_patient, %{}, session, socket)
      assert socket.assigns.current_user.id == user.id
      assert socket.assigns.current_user.patient.name == "Harold Melvin"
      assert socket.assigns.current_user.patient.user_id == user.id
    end

    test "redirects unauthorized users", %{conn: conn, user: user} do
      user_token = Accounts.generate_user_session_token(user)
      session = conn |> put_session(:user_token, user_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: AnkaaWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, socket} = RoleAuth.on_mount(:require_patient, %{}, session, socket)
      assert socket.redirected == {:redirect, %{to: "/register", status: 302}}

      assert Phoenix.Flash.get(socket.assigns.flash, :error) ==
               "You must be a patient to access this page."
    end
  end
end
