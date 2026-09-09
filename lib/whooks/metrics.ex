defmodule Whooks.Metrics do
  import Ecto.Query, warn: false

  alias Whooks.Repo
  alias Whooks.Events.Event
  alias Whooks.DeliveryAttempts.DeliveryAttempt
  alias Whooks.Subscriptions.Subscription
  alias Whooks.Endpoints.Endpoint
  alias Whooks.Common.Utils

  require Logger

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

  def count_subscriptions(opts) do
    query =
      from(s in Subscription,
        join: e in Endpoint,
        on: e.id == s.endpoint_id,
        as: :endpoint,
        group_by: s.topic_id,
        select: %{topic_id: s.topic_id, count: count(s.id)}
      )

    Enum.reduce(opts, query, fn
      {:consumer_id, consumer_id}, q ->
        where(q, [_s, e], e.consumer_id == ^consumer_id)

      {:project_id, project_id}, q ->
        where(q, [_s, e], e.project_id == ^project_id)

      _, q ->
        q
    end)
    |> Repo.all()
    |> case do
      nil ->
        {:ok, 0}

      data ->
        {:ok, data}
    end
  end

  def events_kpi(opts) do
    base_query =
      Event
      |> join(:inner, [e], da in DeliveryAttempt, on: da.event_id == e.id)
      |> apply_filters(opts)
      |> windows([_e, da], latency_window: [order_by: [asc: da.latency_ms]])
      |> select([_e, da], %{
        id: da.id,
        res_status: da.res_status,
        status: da.status,
        latency_ms: da.latency_ms,
        ranking: over(percent_rank(), :latency_window)
      })

    from(a in subquery(base_query),
      select: %{
        total_attempts: count(a.id),
        success_rate:
          fragment(
            "ROUND(COUNT(CASE WHEN ? = 'success' THEN 1 END) * 100.0 / NULLIF(COUNT(?), 0), 2)",
            a.status,
            a.id
          ),
        success_count: fragment("COUNT(CASE WHEN ? = 'success' THEN 1 END)", a.status),
        failed_count: fragment("COUNT(CASE WHEN ? = 'failed' THEN 1 END)", a.status),
        p95_latency_ms:
          fragment(
            "MIN(CASE WHEN ? >= 0.95 THEN ? END)",
            a.ranking,
            a.latency_ms
          )
      }
    )
    |> Repo.one()
    |> case do
      nil ->
        {:ok, nil}

      data ->
        {:ok, data}
    end
  end

  def delivery_attempts_kpi(opts) do
    base_query =
      Event
      |> join(:inner, [e], da in DeliveryAttempt, on: da.event_id == e.id)
      |> apply_filters(opts)
      |> windows([_e, da], latency_window: [order_by: [asc: da.latency_ms]])
      |> select([_e, da], %{
        id: da.id,
        res_status: da.res_status,
        status: da.status,
        latency_ms: da.latency_ms,
        ranking: over(percent_rank(), :latency_window)
      })

    from(a in subquery(base_query),
      select: %{
        total_attempts: count(a.id),
        success_rate:
          fragment(
            "ROUND(COUNT(CASE WHEN ? = 'success' THEN 1 END) * 100.0 / NULLIF(COUNT(?), 0), 2)",
            a.status,
            a.id
          ),
        success_count: fragment("COUNT(CASE WHEN ? = 'success' THEN 1 END)", a.status),
        failed_count: fragment("COUNT(CASE WHEN ? = 'failed' THEN 1 END)", a.status),
        p95_latency_ms:
          fragment(
            "MIN(CASE WHEN ? >= 0.95 THEN ? END)",
            a.ranking,
            a.latency_ms
          )
      }
    )
    |> Repo.one()
    |> case do
      nil ->
        {:ok, nil}

      data ->
        {:ok, data}
    end
  end

  def count_active_subscriptions(opts) do
    consumer_id = Keyword.get(opts, :consumer_id)

    Endpoint
    |> join(:inner, [e], s in Subscription, on: s.endpoint_id == e.id)
    |> where(
      [e, s],
      e.consumer_id == ^consumer_id and
        s.status == :enabled and
        e.status == :enabled
    )
    |> select([_e, s], count(s.id))
    |> Repo.one()
    |> case do
      nil -> {:ok, 0}
      data -> {:ok, data}
    end
  end

  def count_endpoints_by_consumer(consumer_id) do
    from(e in Endpoint,
      where: e.consumer_id == ^consumer_id,
      select: count(e.id)
    )
    |> Repo.one()
    |> case do
      [] ->
        {:ok, []}

      data ->
        {:ok, data}
    end
  end

  def events(opts \\ []) do
    last = Keyword.get(opts, :last)
    interval = Keyword.get(opts, :interval)
    step_seconds = interval_seconds(interval)
    date_format = sql_date_format(interval)
    start_dt = Utils.parse_last_to_date_time(last) |> trunc_to_interval(interval)
    end_dt = NaiveDateTime.utc_now() |> trunc_to_interval(interval)

    from(e in Event,
      group_by: [
        selected_as(:date_time),
        e.status
      ],
      order_by: [asc: selected_as(:date_time)],
      select: %{
        date_time:
          selected_as(
            fragment(
              "DATE_FORMAT(FROM_UNIXTIME(FLOOR(UNIX_TIMESTAMP(?) / ?) * ?), ?)",
              e.inserted_at,
              ^step_seconds,
              ^step_seconds,
              ^date_format
            ),
            :date_time
          ),
        status: e.status,
        count: fragment("coalesce(count(*), 0)")
      }
    )
    |> apply_filters(opts)
    |> Repo.all()
    |> case do
      [] ->
        {:ok, []}

      events ->
        filled_events = fill_time_series(events, start_dt, end_dt, interval)

        {:ok, filled_events}
    end
  end

  defp apply_filters(q, opts) do
    Enum.reduce(opts, q, fn
      {:consumer_id, consumer_id}, q ->
        where(q, [e], e.consumer_id == ^consumer_id)

      {:project_id, project_id}, q ->
        where(q, [e], e.project_id == ^project_id)

      {:last, last}, q ->
        where(
          q,
          [e],
          e.inserted_at >= ^Utils.parse_last_to_date_time(last) and
            e.inserted_at <= fragment("now()")
        )

      _, q ->
        q
    end)
  end

  defp fill_time_series(db_events, start_dt, end_dt, interval) do
    # Create lookup map: %{{~N[2026-07-31 14:00:00], :delivered} => 12}
    db_map =
      Map.new(db_events, fn %{date_time: date_time, status: status, count: count} ->
        {{parse_date_time(date_time, interval), status}, count}
      end)

    # Get distinct statuses found in the query (or default to empty if none)
    statuses =
      case Enum.map(db_events, & &1.status) |> Enum.uniq() do
        [] -> []
        list -> list
      end

    # Generate all time buckets in range
    time_buckets = build_time_buckets(start_dt, end_dt, interval)

    # Merge buckets with DB data for every status
    for bucket <- time_buckets, status <- statuses do
      count = Map.get(db_map, {bucket, status}, 0)

      %{
        date_time: format_output_string(bucket),
        status: status,
        count: count
      }
    end
  end

  defp build_time_buckets(start_dt, end_dt, interval) do
    step_seconds = interval_seconds(interval)

    Stream.unfold(start_dt, fn current ->
      if NaiveDateTime.compare(current, end_dt) in [:lt, :eq] do
        next = NaiveDateTime.add(current, step_seconds, :second)
        {current, next}
      else
        nil
      end
    end)
    |> Enum.to_list()
  end

  defp sql_date_format(interval) do
    case interval do
      interval when interval in ["1s", "15s", "30s", "45s"] ->
        "%Y-%m-%d %H:%i:%S"

      interval when interval in ["1m", "15m", "30m", "45m", "1h", "12h", "24h", "48h"] ->
        "%Y-%m-%d %H:%i"

      "24h" ->
        "%Y-%m-%d %H:%i"

      "48h" ->
        "%Y-%m-%d %H:%i"

      "1d" ->
        "%Y-%m-%d"

      "1w" ->
        "%Y-%m-%d"

      "1mo" ->
        "%Y-%m-%d"

      _ ->
        "%Y-%m-%d"
    end
  end

  defp interval_seconds(interval) do
    case interval do
      "1s" -> 1
      "15s" -> 15
      "30s" -> 30
      "45s" -> 45
      "1m" -> 60
      "15m" -> 15 * 60
      "30m" -> 30 * 60
      "45m" -> 45 * 60
      "1h" -> 60 * 60
      "12h" -> 12 * 60 * 60
      "24h" -> 24 * 60 * 60
      "48h" -> 48 * 60 * 60
      "1d" -> 24 * 60 * 60
      "1w" -> 7 * 24 * 60 * 60
      "1mo" -> 30 * 24 * 60 * 60
      _ -> 60
    end
  end

  defp parse_date_time(str, _interval) do
    case String.length(str) do
      10 -> NaiveDateTime.from_iso8601!("#{str} 00:00:00")
      16 -> NaiveDateTime.from_iso8601!("#{str}:00")
      _ -> NaiveDateTime.from_iso8601!(str)
    end
  end

  defp format_output_string(dt), do: NaiveDateTime.to_string(dt)

  defp trunc_to_interval(%DateTime{} = dt, interval) do
    DateTime.to_naive(dt) |> trunc_to_interval(interval)
  end

  defp trunc_to_interval(%NaiveDateTime{} = dt, interval) do
    step_seconds = interval_seconds(interval)

    dt
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_unix(:second)
    |> then(&(div(&1, step_seconds) * step_seconds))
    |> DateTime.from_unix!(:second)
    |> DateTime.to_naive()
  end
end
