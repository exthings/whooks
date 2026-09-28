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

    with :ok <- Bodyguard.permit(Projects, :list, conn.assigns.current_scope, []) do
      conn
      |> assign_prop(:id, params["id"])
      |> assign_projects(params)
      |> render_inertia("projects/index")
    end
  end

  def show(conn, params) do
    project_id = params["id"]

    with :ok <- Bodyguard.permit(Projects, :get, conn.assigns.current_scope, []),
         {:ok, project} <- Projects.get_by_id(project_id) do
      conn
      |> assign_prop(:id, project_id)
      |> assign_prop(:project, Serializer.to_map(project))
      |> assign_projects(params)
      |> assign_events(params)
      |> assign_events_metrics(params)
      |> assign_attempts_metrics(params)
      |> assign_events_kpi(params)
      |> assign_attempts_kpi(params)
      |> assign_subscriptions(params)
      |> render_inertia("projects/index")
    end
  end

  def recover_failed(conn, %{"organization_id" => org_id, "id" => id} = params) do
    with :ok <- Bodyguard.permit(Events, :retry_failed, conn.assigns.current_scope, []),
         {:ok, project} <- Projects.get_by_id(id) do
      data = Map.put(params, "project_id", project.id)

      case Events.retry_failed(data) do
        {:ok, %{total_enqueued: count}} ->
          conn
          |> put_flash(:info, "Successfully enqueued #{count} failed event(s) for retry")
          |> redirect(to: ~p"/ui/admin/#{org_id}/projects/#{id}")

        {:error, reason} ->
          conn
          |> put_flash(:error, "Failed to retry events: #{inspect(reason)}")
          |> redirect(to: ~p"/ui/admin/#{org_id}/projects/#{id}")
      end
    end
  end

  def bulk_replay(conn, %{"organization_id" => org_id, "id" => id} = params) do
    with :ok <- Bodyguard.permit(Events, :replay, conn.assigns.current_scope, []),
         {:ok, project} <- Projects.get_by_id(id) do
      data = Map.put(params, "project_id", project.id)

      case Events.replay(data) do
        {:ok, %{total_enqueued: count}} ->
          conn
          |> put_flash(:info, "Successfully enqueued #{count} event(s) for replay")
          |> redirect(to: ~p"/ui/admin/#{org_id}/projects/#{id}")

        {:error, reason} ->
          conn
          |> put_flash(:error, "Failed to bulk replay events: #{inspect(reason)}")
          |> redirect(to: ~p"/ui/admin/#{org_id}/projects/#{id}")
      end
    end
  end

  defp assign_projects(conn, params) do
    organization_id = Map.get(conn.params, "organization_id")

    conn
    |> assign_prop(:projects, fn ->
      Projects.list(params, organization_id: organization_id)
      |> case do
        {:ok, {projects, meta}} ->
          %{data: Serializer.to_map(projects), meta: meta}
      end
    end)
  end

  defp assign_events(conn, params) do
    project_id = Map.get(params, "id")
    global_filters = conn.assigns.global_filters

    conn
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
  end

  def assign_events_metrics(conn, params) do
    project_id = Map.get(params, "id")
    global_filters = conn.assigns.global_filters

    conn
    |> assign_prop(
      :events_metrics,
      inertia_defer(fn ->
        {:ok, events_stats} =
          Metrics.events(
            project_id: project_id,
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
  end

  def assign_attempts_metrics(conn, params) do
    project_id = Map.get(params, "id")
    global_filters = conn.assigns.global_filters

    conn
    |> assign_prop(
      :attempts_metrics,
      inertia_defer(fn ->
        {:ok, attempts_stats} =
          Metrics.delivery_attempts(
            project_id: project_id,
            interval: global_filters.interval,
            last: global_filters.last
          )

        %{
          data: attempts_stats,
          interval: global_filters.interval,
          last: global_filters.last
        }
      end)
    )
  end

  def assign_events_kpi(conn, params) do
    project_id = Map.get(params, "id")
    global_filters = conn.assigns.global_filters

    conn
    |> assign_prop(
      :events_kpi,
      inertia_defer(fn ->
        Metrics.events_kpi(
          project_id: project_id,
          last: global_filters.last
        )
        |> case do
          {:ok, data} -> data
        end
      end)
    )
  end

  def assign_attempts_kpi(conn, params) do
    project_id = Map.get(params, "id")
    global_filters = conn.assigns.global_filters

    conn
    |> assign_prop(
      :attempts_kpi,
      inertia_defer(fn ->
        Metrics.delivery_attempts_kpi(
          project_id: project_id,
          last: global_filters.last
        )
        |> case do
          {:ok, data} -> data
        end
      end)
    )
  end

  def assign_subscriptions(conn, params) do
    project_id = Map.get(params, "id")

    conn
    |> assign_prop(
      :subscriptions,
      inertia_defer(fn ->
        {:ok, subscriptions} = Metrics.count_subscriptions(project_id: project_id)
        subscriptions
      end)
    )
  end
end
