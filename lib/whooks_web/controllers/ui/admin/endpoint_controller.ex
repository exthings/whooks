defmodule WhooksWeb.UI.Admin.EndpointController do
  use WhooksWeb, :controller

  alias Whooks.Events
  alias Whooks.Endpoints
  alias Whooks.Metrics
  alias Whooks.Serializer

  action_fallback WhooksWeb.UI.FallbackController

  require Logger

  def show(conn, %{"id" => id} = params) do
    with :ok <- Bodyguard.permit(Endpoints, :get, conn.assigns.current_scope, []),
         {:ok, endpoint} <- Endpoints.get_by_id(id) do
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

  def recover_failed(conn, %{"organization_id" => org_id, "id" => id} = params) do
    with :ok <- Bodyguard.permit(Events, :retry_failed, conn.assigns.current_scope, []),
         {:ok, endpoint} <- Endpoints.get_by_id(id) do
      opts = [
        consumer_id: endpoint.consumer_id,
        project_id: endpoint.project_id
      ]

      opts =
        case params["since"] do
          since when is_binary(since) and since != "" -> Keyword.put(opts, :inserted_after, since)
          _ -> opts
        end

      case Events.retry_failed(opts) do
        {:ok, %{total_enqueued: count}} ->
          conn
          |> put_flash(:info, "Successfully enqueued #{count} failed event(s) for retry")
          |> redirect(to: ~p"/ui/admin/#{org_id}/endpoints/#{id}")

        {:error, reason} ->
          conn
          |> put_flash(:error, "Failed to retry events: #{inspect(reason)}")
          |> redirect(to: ~p"/ui/admin/#{org_id}/endpoints/#{id}")
      end
    end
  end

  def replay_missing(conn, %{"organization_id" => org_id, "id" => id} = params) do
    with :ok <- Bodyguard.permit(Events, :retry_missing, conn.assigns.current_scope, []),
         {:ok, endpoint} <- Endpoints.get_by_id(id) do
      opts = []

      opts =
        case params["since"] do
          since when is_binary(since) and since != "" -> Keyword.put(opts, :inserted_after, since)
          _ -> opts
        end

      case Events.retry_missing(endpoint, opts) do
        {:ok, %{total_enqueued: count}} ->
          conn
          |> put_flash(:info, "Successfully enqueued #{count} missing event(s) for replay")
          |> redirect(to: ~p"/ui/admin/#{org_id}/endpoints/#{id}")

        {:error, reason} ->
          conn
          |> put_flash(:error, "Failed to replay missing events: #{inspect(reason)}")
          |> redirect(to: ~p"/ui/admin/#{org_id}/endpoints/#{id}")
      end
    end
  end

  def bulk_replay(conn, %{"organization_id" => org_id, "id" => id} = params) do
    with :ok <- Bodyguard.permit(Events, :bulk_replay, conn.assigns.current_scope, []),
         {:ok, endpoint} <- Endpoints.get_by_id(id) do
      opts = [
        consumer_id: endpoint.consumer_id,
        project_id: endpoint.project_id
      ]

      opts =
        opts
        |> maybe_put_date(:inserted_after, params["since"])
        |> maybe_put_date(:inserted_before, params["until"])
        |> maybe_put_topics(params["topic_ids"])

      case Events.bulk_replay(opts) do
        {:ok, %{total_enqueued: count}} ->
          conn
          |> put_flash(:info, "Successfully enqueued #{count} event(s) for replay")
          |> redirect(to: ~p"/ui/admin/#{org_id}/endpoints/#{id}")

        {:error, reason} ->
          conn
          |> put_flash(:error, "Failed to bulk replay events: #{inspect(reason)}")
          |> redirect(to: ~p"/ui/admin/#{org_id}/endpoints/#{id}")
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
