defmodule WhooksWeb.UI.Admin.EndpointController do
  use WhooksWeb, :controller

  alias Whooks.Common
  alias Whooks.Events
  alias Whooks.Endpoints
  alias Whooks.Metrics
  alias Whooks.Serializer

  require Logger

  def show(conn, %{"id" => id} = params) do
    with {:ok, endpoint} <- Endpoints.get_by_id(id) do
      conn
      |> assign_prop(:endpoint, Serializer.to_map(endpoint))
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
      |> render_inertia("endpoints/show")
    end
  end
end
