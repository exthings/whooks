defmodule WhooksWeb.UI.Consumer.EndpointController do
  use WhooksWeb, :controller

  alias Whooks.Events
  alias Whooks.Endpoints
  alias Whooks.Metrics
  alias Whooks.Serializer

  require Logger

  def index(conn, params) do
    with {:ok, {endpoints, meta}} <- Endpoints.list(conn.assigns.current_scope, params) do
      conn
      |> assign_prop(:endpoints, %{
        data: Serializer.to_map(endpoints),
        meta: Serializer.to_map(meta)
      })
      |> render_inertia("consumers/portal/endpoints/index")
    end
  end

  def show(conn, params) do
    with {:ok, endpoint} <- Endpoints.get(conn.assigns.current_scope, params["id"]) do
      conn
      |> assign_prop(:id, params["id"])
      |> assign_prop(:endpoint, fn -> Serializer.to_map(endpoint) end)
      |> assign_prop(:endpoints, fn ->
        Endpoints.list(conn.assigns.current_scope, params)
        |> case do
          {:ok, {endpoints, meta}} ->
            %{
              data: Serializer.to_map(endpoints),
              meta: Serializer.to_map(meta)
            }
        end
      end)
      |> assign_prop(
        :events,
        inertia_defer(fn ->
          {:ok, {events, meta}} = Events.list_by_endpoint(%{}, endpoint.id)
          %{data: Serializer.to_map(events), meta: Serializer.to_map(meta)}
        end)
      )
      |> assign_prop(
        :events_metrics,
        inertia_defer(fn ->
          interval = Map.get(params, "eventsMetrics", %{}) |> Map.get("interval", "hour")
          last = Map.get(params, "eventsMetrics", %{}) |> Map.get("last", "24h")

          {:ok, events_stats} =
            Metrics.EndpointStats.timeseries(
              endpoint_id: endpoint.id,
              interval: interval,
              last: last
            )

          %{
            data: events_stats,
            interval: interval,
            last: last
          }
        end)
      )
      |> render_inertia("consumers/portal/endpoints/index")
    end
  end
end
