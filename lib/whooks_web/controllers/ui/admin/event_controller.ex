defmodule WhooksWeb.UI.Admin.EventController do
  use WhooksWeb, :controller

  alias Whooks.Events
  alias Whooks.Serializer

  require Logger

  def index(conn, params) do
    events_params = Map.get(params, "events_params", %{}) |> Map.put_new("page_size", 20)

    with {:ok, {events, meta}} <-
           Events.list(events_params, organization_id: params["organization_id"]) do
      conn
      |> assign_prop(:events, %{data: Serializer.to_map(events), meta: Serializer.to_map(meta)})
      |> render_inertia("events/index")
    end
  end

  def show(conn, params) do
    with {:ok, event} <- Events.get(params["id"], organization_id: params["organization_id"]) do
      conn
      |> assign_prop(:event, Serializer.to_map(event))
      |> render_inertia("events/show")
    end
  end

  def resend(conn, params) do
    with {:ok, event} <- Events.get(params["id"], organization_id: params["organization_id"]) do
      Events.enqueue_event(event)
      |> case do
        {:ok, _} ->
          conn
          |> put_flash(:info, "Event enqueued")
          |> redirect(to: ~p"/ui/admin/#{params["organization_id"]}/events/#{params["id"]}")

        {:error, reason} ->
          conn
          |> put_flash(:error, "Failed to enqueue event: #{inspect(reason)}")
          |> redirect(to: ~p"/ui/admin/#{params["organization_id"]}/events/#{params["id"]}")
      end
    end
  end
end
