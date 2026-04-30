defmodule WhooksWeb.UI.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use WhooksWeb, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> render_inertia("errors/not-found")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> render_inertia("errors/unauthorized")
  end
end
