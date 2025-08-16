defmodule AnkaaWeb.UserRegistrationLiveTest do
  use AnkaaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Ankaa.AccountsFixtures
  alias Ankaa.AccountsFixtures
  alias Ankaa.Accounts
  alias Ankaa.Invites

  setup do
    # A doctor who can send an invitation in the "with a token" test.
    doctor_user = AccountsFixtures.doctor_fixture()

    %{doctor_user: doctor_user}
  end

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "Register"
      assert html =~ "Log in"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/register")
        |> follow_redirect(conn, ~p"/register")

      assert {:ok, _conn} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"email" => "with spaces", "password" => "too short"})

      assert result =~ "Register"
      assert result =~ "must have the @ sign and no spaces"
      assert result =~ "should be at least 12 character"
    end
  end

  describe "register user" do
    test "without an invite token, creates account and redirects to homepage", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/users/register")

      email = unique_user_email()
      render_submit(form(view, "#registration_form", user: valid_user_attributes(email: email)))

      user = Accounts.get_user_by_email(email)
      login_token = Accounts.generate_temporary_login_token(user)
      conn = get(conn, ~p"/users/log_in_from_token?token=#{login_token}&return_to=/")

      assert redirected_to(conn) == ~p"/"

      conn = get(conn, ~p"/users/settings")
      assert html_response(conn, 200) =~ "Settings"
    end

    test "with an invite token, registers and navigates to accept the invite", %{conn: conn} do
      doctor_inviter = AccountsFixtures.doctor_fixture()
      invitee_email = unique_user_email()
      invite_attrs = %{"invitee_email" => invitee_email, "invitee_role" => "patient"}
      {:ok, invite} = Invites.create_invite(doctor_inviter, invite_attrs)

      {:ok, view, _html} = live(conn, ~p"/users/register?invite_token=#{invite.token}")

      render_submit(
        form(view, "#registration_form", user: valid_user_attributes(email: invitee_email))
      )

      user = Accounts.get_user_by_email(invitee_email)
      login_token = Accounts.generate_temporary_login_token(user)

      return_to = ~p"/invites/accept?token=#{invite.token}"
      conn = get(conn, ~p"/users/log_in_from_token?token=#{login_token}&return_to=#{return_to}")

      assert redirected_to(conn) == ~p"/invites/accept?token=#{invite.token}"
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      user = user_fixture(%{email: "test@email.com"})

      result =
        lv
        |> form("#registration_form",
          user: %{"email" => user.email, "password" => "valid_password"}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      {:ok, _login_live, login_html} =
        lv
        |> element(~s|main a:fl-contains("Log in")|)
        |> render_click()
        |> follow_redirect(conn, ~p"/users/login")

      assert login_html =~ "Log in"
    end
  end
end
