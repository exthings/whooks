defmodule WhooksWeb.UI.Admin.EventController do
  use WhooksWeb, :controller

  alias Whooks.Events
  alias Whooks.Common
  alias Whooks.Serializer

  require Logger

  def show(conn, params) do
    with {:ok, event} <- Events.get(params["id"]) do
      conn
      |> assign_prop(:event, Serializer.to_map(event))
      |> render_inertia("events/show")
    end
  end
end
