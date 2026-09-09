defmodule WhooksWeb.UI.Admin.ProjectController do
  use WhooksWeb, :controller

  alias Whooks.Projects
  alias Whooks.Events
  alias Whooks.Serializer
  alias Whooks.Metrics

  action_fallback WhooksWeb.UI.FallbackController

  plug WhooksWeb.Plugs.GlobalFilters

  require Logger

  def index(conn, params) do
    Logger.info("params: #{inspect(conn.req_headers)}")

    with :ok <- Bodyguard.permit(Projects, :list, conn.assigns.current_scope, []),
         {:ok, {projects, meta}} <-
           Projects.list(params, organization_id: params["organization_id"]) do
      conn
      |> assign_prop(:id, params["id"])
      |> assign_prop(:projects, %{data: Serializer.to_map(projects), meta: meta})
      |> render_inertia("projects/index")
    end
  end

  def show(conn, params) do
    project_id = params["id"]
    global_filters = conn.assigns.global_filters

    with :ok <- Bodyguard.permit(Projects, :get, conn.assigns.current_scope, []),
         {:ok, project} <- Projects.get_by_id(project_id) do
      conn
      |> assign_prop(:id, project_id)
      |> assign_prop(:project, Serializer.to_map(project))
      |> assign_prop(
        :projects,
        fn ->
          Projects.list(Map.get(params, "projects", %{}))
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
              project_id: project_id,
              last: global_filters.last
            )

          %{data: Serializer.to_map(events), meta: Serializer.to_map(meta)}
        end)
      )
      |> assign_prop(
        :events_metrics,
        inertia_defer(fn ->
          {:ok, events_stats} =
            Metrics.events(
              project_id: project.id,
              interval: global_filters.interval,
              last: global_filters.last
            )

          %{
            data: events_stats,
            interval: global_filters.interval,
            last: global_filters.last
          }
        end)
      )
      |> assign_prop(
        :events_kpi,
        inertia_defer(fn ->
          Metrics.events_kpi(
            project_id: project.id,
            last: global_filters.last
          )
          |> case do
            {:ok, data} -> data
          end
        end)
      )
      |> assign_prop(
        :subscriptions,
        inertia_defer(fn ->
          {:ok, subscriptions} = Metrics.count_subscriptions(project_id: project.id)
          subscriptions
        end)
      )
      |> render_inertia("projects/index")
    end
  end
end
