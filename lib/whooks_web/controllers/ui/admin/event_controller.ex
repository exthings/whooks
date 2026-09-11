defmodule WhooksWeb.UI.Admin.EventController do
  use WhooksWeb, :controller

  alias Whooks.Events
  alias Whooks.Projects
  alias Whooks.Consumers
  alias Whooks.Serializer

  action_fallback WhooksWeb.UI.FallbackController

  plug WhooksWeb.Plugs.GlobalFilters

  require Logger

  def index(conn, params) do
    scope = conn.assigns.current_scope
    events_params = Map.get(params, "events_params", %{}) |> Map.put_new("page_size", 20)
    projects_params = Map.get(params, "projects_params", %{})
    consumers_params = Map.get(params, "consumers_params", %{})

    with :ok <- Bodyguard.permit(Events, :list, scope, []) do
      conn
      |> assign_events(events_params)
      |> assing_projects(projects_params)
      |> assing_consumers(consumers_params)
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

  defp assign_events(conn, params) do
    organization_id = Map.get(conn.params, "organization_id")
    global_filters = conn.assigns.global_filters
    Logger.info(params)

    conn
    |> assign_prop(:events, fn ->
      Events.list(params, organization_id: organization_id, last: global_filters.last)
      |> serialize_paginated()
    end)
  end

  defp assing_projects(conn, params) do
    organization_id = Map.get(conn.params, "organization_id")

    conn
    |> assign_prop(:projects, fn ->
      Projects.list(params, organization_id: organization_id)
      |> serialize_paginated()
    end)
  end

  defp assing_consumers(conn, params) do
    organization_id = Map.get(conn.params, "organization_id")

    conn
    |> assign_prop(:consumers, fn ->
      Consumers.list(params, organization_id: organization_id)
      |> serialize_paginated()
    end)
    |> render_inertia("events/index")
  end

  defp serialize_paginated({:ok, {data, meta}}) do
    %{data: Serializer.to_map(data), meta: Serializer.to_map(meta)}
  end

  defp serialize_paginated(_error) do
    %{data: [], meta: %{}}
  end
end
