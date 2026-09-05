defmodule WhooksWeb.UI.Consumer.ProjectController do
  use WhooksWeb, :controller

  alias Whooks.Projects
  alias Whooks.Events
  alias Whooks.Serializer

  action_fallback WhooksWeb.UI.FallbackController

  require Logger

  def index(conn, params) do
    scope = conn.assigns.current_scope

    with {:ok, {projects, meta}} <-
           Projects.list(params, organization_id: scope.consumer.organization_id) do
      conn
      |> assign_prop(:id, params["id"])
      |> assign_prop(:projects, %{data: Serializer.to_map(projects), meta: meta})
      |> render_inertia("consumers/portal/projects")
    end
  end

  def show(conn, params) do
    project_id = params["id"]
    scope = conn.assigns.current_scope

    with {:ok, project} <- Projects.get_by_id(project_id) do
      conn
      |> assign_prop(:id, project_id)
      |> assign_prop(:project, Serializer.to_map(project))
      |> assign_prop(
        :projects,
        fn ->
          Projects.list(params)
          |> case do
            {:ok, {projects, meta}} ->
              %{data: Serializer.to_map(projects), meta: meta}
          end
        end
      )
      |> assign_prop(
        :events,
        inertia_defer(fn ->
          {:ok, {events, meta}} =
            Events.list(Map.get(params, "events_params", %{}),
              consumer_id: scope.consumer.id,
              project_id: project_id
            )

          %{data: Serializer.to_map(events), meta: meta}
        end)
      )
      |> assign_prop(
        :subscriptions,
        []
      )
      |> render_inertia("consumers/portal/projects")
    end
  end
end
