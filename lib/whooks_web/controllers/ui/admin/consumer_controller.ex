defmodule WhooksWeb.UI.Admin.ConsumerController do
  use WhooksWeb, :controller

  alias Whooks.Common
  alias Whooks.Events
  alias Whooks.Consumers
  alias Whooks.Metrics
  alias Whooks.Serializer
  alias Whooks.Auth

  require Logger

  def index(conn, params) do
    with {:ok, {consumers, meta}} <-
           Consumers.list(params, organization_id: params["organization_id"]) do
      conn
      |> assign_prop(:id, params["id"])
      |> assign_prop(:consumers, %{
        data: Serializer.to_map(consumers),
        meta: Serializer.to_map(meta)
      })
      |> render_inertia("consumers/index")
    end
  end

  def show(conn, params) do
    with {:ok, consumer} <- Consumers.get_by_id(params["id"]) do
      conn
      |> assign_prop(:id, params["id"])
      |> assign_prop(:consumer, Serializer.to_map(consumer))
      |> assign_prop(:consumers, fn ->
        Consumers.list(params, organization_id: params["organization_id"])
        |> case do
          {:ok, {consumers, meta}} ->
            %{data: Serializer.to_map(consumers), meta: Serializer.to_map(meta)}
        end
      end)
      |> assign_prop(
        :events,
        inertia_defer(fn ->
          {:ok, {events, meta}} =
            Events.list(Map.get(params, "events_params", %{}), consumer_id: consumer.id)

          %{data: Serializer.to_map(events), meta: Serializer.to_map(meta)}
        end)
      )
      |> assign_prop(
        :events_metrics,
        inertia_defer(fn ->
          interval = Map.get(params, "eventsMetrics", %{}) |> Map.get("interval", "hour")
          last = Map.get(params, "eventsMetrics", %{}) |> Map.get("last", "24h")

          {:ok, events_stats} =
            Metrics.EventStats.timeseries(
              consumer_id: consumer.id,
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
      |> assign_prop(
        :portal_link,
        inertia_optional(fn ->
          token = Auth.create_consumer_portal_link(consumer)
          url(~p"/ui/consumers/login/#{token}")
        end)
      )
      |> render_inertia("consumers/index")
    end
  end

  def create(conn, params) do
    with {:ok, consumer} <- Consumers.create_consumer(params) do
      conn
      |> redirect(to: ~p"/ui/admin/#{params["organization_id"]}/consumers/#{consumer.id}")
    else
      {:error, changeset} ->
        conn
        |> assign_errors(changeset)
        |> redirect(to: ~p"/ui/admin/#{params["organization_id"]}/consumers")
    end
  end

  def create_portal_link(conn, params) do
    with {:ok, consumer} <- Consumers.get_by_id(params["id"]) do
      conn
      |> put_flash(:info, "Portal link for #{consumer.name} created.")
      |> redirect(to: ~p"/ui/admin/#{params["organization_id"]}/consumers/#{consumer.id}")
    end
  end
end
