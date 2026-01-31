defmodule WhooksWeb.V1.EventController do
  use WhooksWeb, :controller

  alias Whooks.Events
  alias Whooks.Events.Event

  action_fallback WhooksWeb.FallbackController

  def index(conn, _params) do
    events = Events.list_events()
    render(conn, :index, events: events)
  end

  def create(conn, event_params) do
    with {:ok, %Event{} = event} <- Events.create_event(event_params) do
      conn
      |> put_status(:created)
      |> render(:show, event: event)
    end
  end

  def show(conn, %{"id" => id}) do
    event = Events.get_event!(id)
    render(conn, :show, event: event)
  end
end
