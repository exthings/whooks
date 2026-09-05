defmodule WhooksWeb.UI.Consumer.HomeController do
  use WhooksWeb, :controller

  alias Whooks.Repo
  alias Whooks.Projects
  alias Whooks.Events
  alias Whooks.Endpoints
  alias Whooks.Metrics
  alias Whooks.Serializer

  require Logger

  @last_to_interval %{
    "1h" => "minute",
    "12h" => "hour",
    "24h" => "hour",
    "48h" => "hour",
    "7d" => "day",
    "1w" => "day",
    "30d" => "day",
    "1mo" => "day"
  }

  def index(conn, params) do
    scope = conn.assigns.current_scope
    consumer = scope.consumer

    last = Map.get(params, "last", "24h")
    project_id = Map.get(params, "project_id")
    project_id = if project_id in ["", "all", nil], do: nil, else: project_id
    interval = Map.get(@last_to_interval, last, "hour")

    {:ok, {projects, _meta}} =
      Projects.list(%{"page_size" => 100}, organization_id: consumer.organization_id)

    conn
    |> assign_prop(:projects, Serializer.to_map(projects))
    |> assign_prop(:filters, %{last: last, project_id: project_id})
    |> assign_prop(
      :kpis,
      inertia_defer(fn ->
        opts = [last: last] ++ if(project_id, do: [project_id: project_id], else: [])
        {:ok, kpis} = Metrics.consumer_kpis(consumer.id, opts)
        kpis
      end)
    )
    |> assign_prop(
      :events_metrics,
      inertia_defer(fn ->
        opts =
          [
            consumer_id: consumer.id,
            last: last,
            interval: interval
          ] ++ if(project_id, do: [project_id: project_id], else: [])

        {:ok, events_stats} = Metrics.EventStats.timeseries(opts)

        %{
          data: events_stats,
          interval: interval,
          last: last
        }
      end)
    )
    |> assign_prop(
      :events,
      inertia_defer(fn ->
        Events.list(scope, %{"page_size" => 5}, last: last)
        |> case do
          {:ok, {events, meta}} ->
            %{data: Serializer.to_map(events), meta: Serializer.to_map(meta)}

          _ ->
            %{data: [], meta: %{}}
        end
      end)
    )
    |> assign_prop(
      :endpoint_health,
      inertia_defer(fn ->
        Endpoints.list(scope, %{"page_size" => 5})
        |> case do
          {:ok, {endpoints, _meta}} ->
            endpoints
            |> Repo.preload(subscriptions: [:topic])
            |> Serializer.to_map()

          _ ->
            []
        end
      end)
    )
    |> render_inertia("consumers/portal/dashboard")
  end
end
