defmodule WhooksWeb.UI.Admin.HomeController do
  use WhooksWeb, :controller

  def home(conn, _params) do
    conn
    |> render_inertia("home")
  end
end
