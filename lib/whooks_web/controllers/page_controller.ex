defmodule WhooksWeb.PageController do
  use WhooksWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def home_inertia(conn, _params) do
    conn
    |> render_inertia("home")
  end
end
