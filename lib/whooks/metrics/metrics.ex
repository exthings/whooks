defmodule Whooks.Metrics do
  import Ecto.Query, warn: false

  alias Whooks.Repo
  alias Whooks.Subscriptions.Subscription
  alias Whooks.Endpoints.Endpoint

  alias Whooks.Events.Event
  alias Whooks.Metrics.Utils

  def count_subscriptions_by_project(project_id) do
    from(s in Subscription,
      join: e in Endpoint,
      on: e.id == s.endpoint_id,
      where: e.project_id == ^project_id,
      group_by: s.topic_id,
      select: %{topic_id: s.topic_id, count: count(s.id)}
    )
    |> Repo.all()
    |> case do
      [] ->
        {:ok, []}

      data ->
        {:ok, data}
    end
  end

  def consumer_kpis(consumer_id, opts \\ []) do
    last = Keyword.get(opts, :last, "24h")
    project_id = Keyword.get(opts, :project_id)
    start_dt = Utils.parse_last_to_date_time(last)

    events_query =
      from(e in Event,
        where: e.consumer_id == ^consumer_id and e.inserted_at >= ^start_dt,
        group_by: e.status,
        select: {e.status, count(e.id)}
      )

    events_query =
      if project_id do
        from(e in events_query, where: e.project_id == ^project_id)
      else
        events_query
      end

    status_counts = Repo.all(events_query) |> Map.new()

    successful_events = Map.get(status_counts, :success, 0) + Map.get(status_counts, "success", 0)
    failed_events = Map.get(status_counts, :failed, 0) + Map.get(status_counts, "failed", 0)
    total_events = Enum.reduce(status_counts, 0, fn {_status, count}, acc -> acc + count end)

    success_rate =
      if total_events > 0 do
        Float.round(successful_events / total_events * 100, 1)
      else
        100.0
      end

    endpoints_query =
      from(ep in Endpoint,
        where: ep.consumer_id == ^consumer_id and ep.status == :enabled,
        select: count(ep.id)
      )

    endpoints_query =
      if project_id do
        from(ep in endpoints_query, where: ep.project_id == ^project_id)
      else
        endpoints_query
      end

    active_endpoints_count = Repo.one(endpoints_query) || 0

    {:ok,
     %{
       total_events: total_events,
       successful_events: successful_events,
       failed_events: failed_events,
       success_rate: success_rate,
       active_endpoints_count: active_endpoints_count
     }}
  end
end
