defmodule WhooksWeb.UI.Consumer.HomeController do
  use WhooksWeb, :controller

  require Logger

  def index(conn, params) do
    conn
    |> render_inertia("consumers/home")
  end
end
