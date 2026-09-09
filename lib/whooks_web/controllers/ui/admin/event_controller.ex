defmodule WhooksWeb.UI.Admin.EventController do
  use WhooksWeb, :controller

  alias Whooks.Events
  alias Whooks.Serializer

  action_fallback WhooksWeb.UI.FallbackController

  plug WhooksWeb.Plugs.GlobalFilters

  require Logger

  def index(conn, params) do
    scope = conn.assigns.current_scope
    global_filters = conn.assigns.global_filters
    events_params = Map.get(params, "events_params", %{}) |> Map.put_new("page_size", 20)
    organization_id = Map.get(params, "organization_id")

    with :ok <- Bodyguard.permit(Events, :list, scope, []),
         {:ok, {events, meta}} <-
           Events.list(events_params, organization_id: organization_id, last: global_filters.last) do
      conn
      |> assign_prop(:events, %{data: Serializer.to_map(events), meta: Serializer.to_map(meta)})
      |> render_inertia("events/index")
    end
  end

  def show(conn, params) do
    with :ok <- Bodyguard.permit(Events, :get, conn.assigns.current_scope, []),
         {:ok, event} <- Events.get(params["id"], organization_id: params["organization_id"]) do
      conn
      |> assign_prop(:event, Serializer.to_map(event))
      |> render_inertia("events/show")
    end
  end

  def resend(conn, params) do
    with :ok <- Bodyguard.permit(Events, :resend, conn.assigns.current_scope, []),
         {:ok, event} <- Events.get(params["id"], organization_id: params["organization_id"]) do
      Events.resend(event)
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
