defmodule AnkaaWeb.Plugs.AuthorizeRole do
  import Plug.Conn
  import Phoenix.Controller
  alias AnkaaWeb.Router.Helpers, as: Routes

  def init(roles) when is_list(roles), do: roles
  def init(role) when is_binary(role), do: [role]

  def call(conn, roles) do
    user = conn.assigns.current_user

    if user && user.role in roles do
      conn
    else
      conn
      |> put_flash(:error, "You are not authorized to access this page.")
      # |> redirect(to: Routes.page_path(conn, :index))
      |> halt()
    end
  end
end
