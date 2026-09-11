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

  def recover_failed(conn, %{"organization_id" => org_id, "id" => id} = params) do
    with :ok <- Bodyguard.permit(Events, :retry_failed, conn.assigns.current_scope, []),
         {:ok, project} <- Projects.get_by_id(id) do
      opts = [project_id: project.id]

      opts =
        case params["since"] do
          since when is_binary(since) and since != "" -> Keyword.put(opts, :inserted_after, since)
          _ -> opts
        end

      case Events.retry_failed(opts) do
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
    with :ok <- Bodyguard.permit(Events, :bulk_replay, conn.assigns.current_scope, []),
         {:ok, project} <- Projects.get_by_id(id) do
      opts = [project_id: project.id]

      opts =
        opts
        |> maybe_put_date(:inserted_after, params["since"])
        |> maybe_put_date(:inserted_before, params["until"])
        |> maybe_put_topics(params["topic_ids"])

      case Events.bulk_replay(opts) do
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

  defp maybe_put_date(opts, _key, nil), do: opts
  defp maybe_put_date(opts, _key, ""), do: opts

  defp maybe_put_date(opts, key, date_str) when is_binary(date_str) do
    Keyword.put(opts, key, date_str)
  end

  defp maybe_put_topics(opts, topic_ids) when is_list(topic_ids) do
    filtered = Enum.reject(topic_ids, &(&1 in [nil, ""]))
    if filtered != [], do: Keyword.put(opts, :topic_ids, filtered), else: opts
  end

  defp maybe_put_topics(opts, _), do: opts
end
