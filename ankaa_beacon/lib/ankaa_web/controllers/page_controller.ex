defmodule AnkaaWeb.PageController do
  use AnkaaWeb, :controller

  def home(conn, _params) do
    if conn.assigns[:current_user] do
      redirect(conn, to: ~p"/dashboard")
    else
      render(conn, :home, layout: false)
    end
  end
end
