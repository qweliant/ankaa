defmodule AnkaaWeb.UserSessionController do
  use AnkaaWeb, :controller

  alias Ankaa.Accounts
  alias AnkaaWeb.UserAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/login")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end

  def log_in_from_token(conn, %{"token" => token, "return_to" => return_to}) do
    case Accounts.get_user_by_temporary_login_token(token) do
      {:ok, user} ->
        # On success, we pass ONLY the `user` struct to log_in_user
        conn
        |> put_flash(:info, "Welcome!")
        |> UserAuth.log_in_user(user, %{"return_to" => return_to})

      {:error, _} ->
        # On failure, we redirect to the login page
        conn
        |> put_flash(:error, "Login link is invalid or has expired.")
        |> redirect(to: ~p"/users/login")
    end
  end
end
