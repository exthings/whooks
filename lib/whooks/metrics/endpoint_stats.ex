defmodule Whooks.Metrics.EndpointStats do
  import Ecto.Query, warn: false

  alias Whooks.Repo

  alias Whooks.Events.Event
  alias Whooks.DeliveryAttempts.DeliveryAttempt
  alias Whooks.Subscriptions.Subscription
  alias Whooks.Metrics.Utils

  def timeseries(opts \\ []) do
    last = Keyword.get(opts, :last, "24h")
    interval = Keyword.get(opts, :interval, "minute")
    date_format = sql_date_format(interval)
    start_dt = Utils.parse_last_to_date_time(last) |> trunc_to_interval(interval)
    end_dt = NaiveDateTime.utc_now() |> trunc_to_interval(interval)

    from(e in Event,
      group_by: [selected_as(:date_time), e.status],
      order_by: [asc: selected_as(:date_time)],
      join: da in DeliveryAttempt,
      on: da.event_id == e.id,
      join: s in Subscription,
      on: s.id == da.subscription_id,
      select: %{
        date_time:
          selected_as(fragment("DATE_FORMAT(?, ?)", e.inserted_at, ^date_format), :date_time),
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
        {:ok, events}
    end
  end

  defp apply_filters(q, opts) do
    Enum.reduce(opts, q, fn
      {:consumer_id, consumer_id}, q ->
        where(q, [e, da, s], e.consumer_id == ^consumer_id)

      {:project_id, project_id}, q ->
        where(q, [e, da, s], e.project_id == ^project_id)

      {:endpoint_id, endpoint_id}, q ->
        where(q, [e, da, s], s.endpoint_id == ^endpoint_id)

      {:last, last}, q ->
        where(
          q,
          [e, da, s],
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
        date_time: format_output_string(bucket, interval),
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

  defp sql_date_format("minute"), do: "%Y-%m-%d %H:%i"
  defp sql_date_format("hour"), do: "%Y-%m-%d %H:00"
  defp sql_date_format("day"), do: "%Y-%m-%d 00:00"

  defp interval_seconds("minute"), do: 60
  defp interval_seconds("hour"), do: 3600
  defp interval_seconds("day"), do: 86_400

  defp parse_date_time(str, "minute"), do: NaiveDateTime.from_iso8601!("#{str}:00")
  defp parse_date_time(str, "hour"), do: NaiveDateTime.from_iso8601!("#{str}:00")
  defp parse_date_time(str, "day"), do: NaiveDateTime.from_iso8601!("#{str}:00")

  defp format_output_string(dt, "minute"), do: NaiveDateTime.to_string(dt) |> String.slice(0..15)
  defp format_output_string(dt, "hour"), do: NaiveDateTime.to_string(dt) |> String.slice(0..15)
  defp format_output_string(dt, "day"), do: NaiveDateTime.to_string(dt) |> String.slice(0..9)

  defp trunc_to_interval(%NaiveDateTime{} = dt, "minute") do
    NaiveDateTime.new!(dt.year, dt.month, dt.day, dt.hour, dt.minute, 0)
  end

  defp trunc_to_interval(%NaiveDateTime{} = dt, "hour") do
    NaiveDateTime.new!(dt.year, dt.month, dt.day, dt.hour, 0, 0)
  end

  defp trunc_to_interval(%NaiveDateTime{} = dt, "day") do
    NaiveDateTime.new!(dt.year, dt.month, dt.day, 0, 0, 0)
  end

  defp trunc_to_interval(%DateTime{} = dt, interval) do
    DateTime.to_naive(dt) |> trunc_to_interval(interval)
  end
end
