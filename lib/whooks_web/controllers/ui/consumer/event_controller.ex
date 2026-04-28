defmodule WhooksWeb.UI.Consumer.EventController do
  use WhooksWeb, :controller

  alias Whooks.Events
  alias Whooks.Serializer

  require Logger

  def index(conn, params) do
    events_params = Map.get(params, "events_params", %{}) |> Map.put_new("page_size", 20)

    with {:ok, {events, meta}} <-
           Events.list(events_params, consumer_id: params["consumer_id"]) do
      conn
      |> assign_prop(:events, %{data: Serializer.to_map(events), meta: Serializer.to_map(meta)})
      |> render_inertia("events/index")
    end
  end

  def show(conn, params) do
    with {:ok, event} <- Events.get(params["id"], consumer_id: params["consumer_id"]) do
      conn
      |> assign_prop(:event, Serializer.to_map(event))
      |> render_inertia("events/show")
    end
  end
end
