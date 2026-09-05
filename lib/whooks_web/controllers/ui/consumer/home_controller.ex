defmodule WhooksWeb.UI.Consumer.HomeController do
  use WhooksWeb, :controller

  require Logger

  def index(conn, _params) do
    conn
    |> render_inertia("consumers/portal/dashboard")
  end
end
