defmodule WhooksWeb.UI.Admin.ConsumerController do
  use WhooksWeb, :controller

  alias Whooks.Common
  alias Whooks.Events
  alias Whooks.Consumers
  alias Whooks.Analytics

  require Logger

  def index(conn, params) do
    with {:ok, {consumers, meta}} <- Consumers.list(params) do
      conn
      |> assign_prop(:consumers, for(consumer <- consumers, do: serialize_consumer(consumer)))
      |> assign_prop(:meta, meta)
      |> assign_prop(:id, params["id"])
      |> render_inertia("consumers/index")
    end
  end

  def show(conn, params) do
    with {:ok, consumer} <- Consumers.get_by_id(params["id"]),
         {:ok, {consumers, meta}} <- Consumers.list(params) do
      conn
      |> assign_prop(:consumer, serialize_consumer(consumer))
      |> assign_prop(:id, params["id"])
      |> assign_prop(:consumers, for(consumer <- consumers, do: serialize_consumer(consumer)))
      |> assign_prop(:meta, meta)
      |> assign_prop(
        :events,
        inertia_defer(fn ->
          {:ok, {events, meta}} = Events.list(params, consumer_id: consumer.id)
          %{data: for(event <- events, do: serialize_event(event)), meta: meta}
        end)
      )
      |> assign_prop(
        :events_metrics,
        inertia_defer(fn ->
          interval = Map.get(params, "eventsMetrics", %{}) |> Map.get("interval", "hour")
          last = Map.get(params, "eventsMetrics", %{}) |> Map.get("last", "24h")

          Logger.info("Interval: #{interval}, Last: #{last}")

          {:ok, events_stats} =
            Analytics.events(consumer_id: consumer.id, interval: interval, last: last)

          %{
            data: events_stats,
            interval: interval,
            last: last
          }
        end)
      )
      |> render_inertia("consumers/index")
    end
  end

  def create(conn, params) do
    with {:ok, consumer} <- Consumers.create_consumer(params) do
      conn
      |> redirect(to: ~p"/ui/admin/consumers/#{consumer.id}")
    else
      {:error, changeset} ->
        conn
        |> assign_errors(changeset)
        |> redirect(to: ~p"/ui/admin/consumers")
    end
  end

  defp serialize_consumer(consumer) do
    %{
      id: consumer.id,
      uid: consumer.uid,
      name: consumer.name,
      metadata: consumer.metadata,
      inserted_at: consumer.inserted_at,
      updated_at: consumer.updated_at,
      endpoints: Common.Ecto.map_if_loaded(consumer.endpoints, &serialize_endpoint/1)
    }
  end

  defp serialize_endpoint(endpoint) do
    %{
      id: endpoint.id,
      uid: endpoint.uid,
      status: endpoint.status,
      url: endpoint.url,
      description: endpoint.description,
      headers: endpoint.headers,
      metadata: endpoint.metadata,
      inserted_at: endpoint.inserted_at,
      updated_at: endpoint.updated_at
    }
  end

  defp serialize_event(event) do
    %{
      id: event.id,
      inserted_at: event.inserted_at,
      updated_at: event.updated_at,
      uid: event.uid,
      status: event.status,
      data: event.data,
      metadata: event.metadata,
      tags: event.tags,
      topic: serialize_topic(event.topic)
    }
  end

  defp serialize_topic(topic) do
    %{
      id: topic.id,
      name: topic.name
    }
  end
end
