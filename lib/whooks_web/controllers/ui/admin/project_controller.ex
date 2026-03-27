defmodule WhooksWeb.UI.Admin.ProjectController do
  use WhooksWeb, :controller

  alias Whooks.Projects
  alias Whooks.Events
  alias Whooks.Serializer
  alias Whooks.Metrics

  def index(conn, params) do
    with {:ok, {projects, meta}} <- Projects.list(params) do
      conn
      |> assign_prop(:id, params["id"])
      |> assign_prop(:projects, %{data: Serializer.to_map(projects), meta: meta})
      |> render_inertia("projects/index")
    end
  end

  def show(conn, params) do
    project_id = params["id"]

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
            Events.list(Map.get(params, "events_params", %{}), project_id: project_id)

          %{data: Serializer.to_map(events), meta: meta}
        end)
      )
      |> assign_prop(
        :subscriptions,
        inertia_defer(fn ->
          {:ok, subscriptions} = Metrics.count_subscriptions_by_project(project_id)
          subscriptions
        end)
      )
      |> render_inertia("projects/index")
    end
  end
end
