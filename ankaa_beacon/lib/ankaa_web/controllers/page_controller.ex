defmodule AnkaaWeb.PageController do
  use AnkaaWeb, :controller
  import AnkaaWeb.UserAuth

  def home(conn, _params) do
    if conn.assigns[:current_user] do
      redirect(conn, to: signed_in_path(conn))
    else
      render(conn, :home, layout: false)
    end
  end
end
