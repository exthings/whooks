defmodule Whooks.Events.Bulk do
  @moduledoc """
  Handles bulk event replay, retries, and background queue dispatching using maps.
  """

  import Ecto.Query, warn: false

  alias Whooks.Repo
  alias Whooks.Events.Event
  alias Whooks.Endpoints.Endpoint
  alias Whooks.Subscriptions.Subscription
  alias Whooks.DeliveryAttempts.DeliveryAttempt

  require Logger

  @queue_name "bulk_operations"
  @job_name "bulk_operation"
  @deliveries_queue "deliveries"
  @default_batch_size 100

  @attempt_statuses ~w(failed success retry discarded scheduled processing)

  # ---------------------------------------------------------------------------
  # Public API (Map-based)
  # ---------------------------------------------------------------------------

  @doc """
  Replays historical events matching filter criteria (topics, date range, project, consumer, endpoint).
  """
  @spec replay(map()) ::
          {:ok, %{total_enqueued: non_neg_integer(), job_ids: [String.t()]}} | {:error, term()}
  def replay(params \\ %{}) when is_map(params), do: enqueue(params)

  @doc """
  Retries events that had failed delivery attempts.
  """
  @spec retry_failed(map()) ::
          {:ok, %{total_enqueued: non_neg_integer(), job_ids: [String.t()]}} | {:error, term()}
  def retry_failed(params \\ %{}) when is_map(params) do
    params
    |> Map.put_new("status", ["failed"])
    |> enqueue()
  end

  @doc """
  Retries past events created before an endpoint or its subscription existed.
  """
  @spec retry_missing(Endpoint.t() | String.t() | TypeID.t(), map()) ::
          {:ok, %{total_enqueued: non_neg_integer(), job_ids: [String.t()]}} | {:error, term()}
  def retry_missing(endpoint_or_id, params \\ %{})

  def retry_missing(%Endpoint{id: id}, params) when is_map(params),
    do: retry_missing(id, params)

  def retry_missing(endpoint_id, params)
      when (is_binary(endpoint_id) or is_struct(endpoint_id, TypeID)) and is_map(params) do
    params
    |> Map.put("endpoint_id", to_string(endpoint_id))
    |> Map.put_new("status", ["unprocessed", "processed", "pending"])
    |> enqueue()
  end

  @doc """
  Resends multiple specific events by IDs or Event structs.
  """
  @spec resend_events([Event.t() | String.t() | TypeID.t()], map()) ::
          {:ok, %{total_enqueued: non_neg_integer(), job_ids: [String.t()]}} | {:error, term()}
  def resend_events(events_or_ids, params \\ %{}) when is_map(params) do
    event_ids =
      events_or_ids
      |> List.wrap()
      |> Enum.map(fn
        %Event{id: id} -> to_string(id)
        %TypeID{} = id -> TypeID.to_string(id)
        id when is_binary(id) -> id
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)

    params
    |> Map.put("event_ids", event_ids)
    |> enqueue()
  end

  @doc """
  Enqueues a bulk operation job to the '#{@queue_name}' BullMQ queue based on filter map.
  Calculates the count of matching events and publishes to the queue.
  """
  def enqueue(params \\ %{}) when is_map(params) do
    filters = normalize_params(params)
    count = Repo.one(from(e in count_events_query(filters), select: count(e.id, :distinct))) || 0

    Logger.info(
      "[Events.Bulk.enqueue] Found #{count} matching events for filters: #{inspect(filters)}"
    )

    if count == 0 do
      {:ok, %{total_enqueued: 0, job_ids: []}}
    else
      batch_size = parse_integer(filters["batch_size"], @default_batch_size)

      data = %{
        "filters" => filters,
        "cursor" => nil,
        "batch_size" => batch_size,
        "total_count" => count,
        "processed_count" => 0
      }

      case BullMQ.Queue.add(@queue_name, @job_name, data, connection: :bullmq_redis) do
        {:ok, job} ->
          Logger.info("[BullMQ] #{@queue_name} enqueued job #{job.id} for #{count} events")
          {:ok, %{total_enqueued: count, job_ids: [to_string(job.id)]}}

        {:error, reason} ->
          Logger.error("[BullMQ] #{@queue_name} enqueue failed: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  @doc """
  Processes bulk operations from the background queue using keyset-paginated batch dispatching.
  Receives a data map from BullMQ worker and processes batches.
  """
  def process(data) when is_map(data) do
    filters = data["filters"] || data
    cursor = data["cursor"]
    batch_size = parse_integer(data["batch_size"] || filters["batch_size"], @default_batch_size)
    total_count = parse_integer(data["total_count"] || data["count"], 0)
    processed_count = parse_integer(data["processed_count"], 0)

    dispatch_batch(filters, batch_size, cursor, total_count, processed_count)
  end

  # ---------------------------------------------------------------------------
  # Keyset Batch Execution
  # ---------------------------------------------------------------------------

  defp dispatch_batch(filters, batch_size, cursor, total_count, processed_count) do
    rows = fetch_batch(filters, cursor, batch_size)

    if rows == [] do
      Logger.info(
        "[Events.Bulk.process] Bulk operation finished. Total processed: #{processed_count}/#{total_count}"
      )

      {:ok, %{successful: processed_count, failed: 0, total: total_count, completed: true}}
    else
      batch_acc = process_batch_rows(rows, %{successful: 0, failed: 0, total: 0})
      {last_event, _, _, _} = List.last(rows)
      new_processed_count = processed_count + batch_acc.successful

      has_more = length(rows) == batch_size

      if has_more do
        next_job_data = %{
          "filters" => filters,
          "cursor" => to_string(last_event.id),
          "batch_size" => batch_size,
          "total_count" => total_count,
          "processed_count" => new_processed_count
        }

        case BullMQ.Queue.add(@queue_name, @job_name, next_job_data, connection: :bullmq_redis) do
          {:ok, job} ->
            Logger.info(
              "[Events.Bulk.process] Enqueued next batch job #{job.id} (cursor: #{last_event.id}, processed #{new_processed_count}/#{total_count})"
            )

            {:ok,
             %{
               successful: batch_acc.successful,
               failed: 0,
               total: total_count,
               completed: false,
               next_job_id: to_string(job.id)
             }}

          {:error, reason} ->
            Logger.error(
              "[Events.Bulk.process] Failed to enqueue next batch job: #{inspect(reason)}"
            )

            {:error, reason}
        end
      else
        Logger.info(
          "[Events.Bulk.process] Bulk operation finished on final batch. Total processed: #{new_processed_count}/#{total_count}"
        )

        {:ok,
         %{
           successful: new_processed_count,
           failed: 0,
           total: max(total_count, new_processed_count),
           completed: true
         }}
      end
    end
  end

  defp fetch_batch(filters, cursor, batch_size) do
    endpoint_id = filters["endpoint_id"]
    base = base_events_query(Event, filters)

    base =
      if cursor do
        where(base, [e], e.id > ^cursor)
      else
        base
      end

    query =
      if endpoint_id do
        from(e in base,
          join: t in assoc(e, :topic),
          join: s in assoc(t, :subscriptions),
          on:
            s.endpoint_id == ^endpoint_id and s.status == :enabled and
              e.inserted_at < s.inserted_at,
          join: ep in assoc(s, :endpoint),
          on:
            ep.id == ^endpoint_id and ep.consumer_id == e.consumer_id and
              ep.project_id == e.project_id and ep.status == :enabled,
          order_by: [asc: e.id],
          limit: ^batch_size,
          select: {e, s, ep, t}
        )
      else
        from(e in base,
          join: t in assoc(e, :topic),
          left_join: s in assoc(t, :subscriptions),
          on: s.status == :enabled,
          left_join: ep in assoc(s, :endpoint),
          on:
            ep.id == s.endpoint_id and ep.consumer_id == e.consumer_id and
              ep.project_id == e.project_id and ep.status == :enabled,
          order_by: [asc: e.id],
          limit: ^batch_size,
          select: {e, s, ep, t}
        )
      end

    Repo.all(query)
  end

  defp process_batch_rows(rows, acc) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    event_chunks = Enum.chunk_by(rows, fn {event, _sub, _ep, _top} -> event.id end)

    initial_batch = %{attempts: [], jobs: [], processing_ids: [], unprocessed_ids: []}

    batch =
      Enum.reduce(event_chunks, initial_batch, fn chunk_rows, batch_acc ->
        {event, _, _, _} = hd(chunk_rows)

        active_subs =
          for {_, s, ep, t} <- chunk_rows, not is_nil(s) and not is_nil(ep), do: {s, ep, t}

        if active_subs == [] do
          %{batch_acc | unprocessed_ids: [event.id | batch_acc.unprocessed_ids]}
        else
          {new_attempts, new_jobs} =
            active_subs
            |> Enum.map(fn {sub, ep, topic} ->
              attempt_id = DeliveryAttempt.gen_id()

              attempt = %{
                id: attempt_id,
                event_id: event.id,
                subscription_id: sub.id,
                status: :scheduled,
                inserted_at: now,
                updated_at: now
              }

              job = DeliveryAttempt.build_bullmq_job(attempt_id)
              {attempt, job}
            end)
            |> Enum.unzip()

          %{
            batch_acc
            | attempts: batch_acc.attempts ++ new_attempts,
              jobs: batch_acc.jobs ++ new_jobs,
              processing_ids: [event.id | batch_acc.processing_ids]
          }
        end
      end)

    if batch.attempts != [] do
      Repo.insert_all(DeliveryAttempt, batch.attempts)

      from(e in Event, where: e.id in ^batch.processing_ids)
      |> Repo.update_all(set: [status: :processing, updated_at: now])
    end

    if batch.unprocessed_ids != [] do
      from(e in Event, where: e.id in ^batch.unprocessed_ids)
      |> Repo.update_all(set: [status: :unprocessed, updated_at: now])
    end

    if batch.jobs != [] do
      case BullMQ.Queue.add_bulk(@deliveries_queue, batch.jobs, connection: :bullmq_redis) do
        {:ok, _} ->
          :ok

        {:error, reason} ->
          Logger.error("[BullMQ] add_bulk error on deliveries: #{inspect(reason)}")
      end
    end

    num_events = length(event_chunks)
    %{acc | successful: acc.successful + num_events, total: acc.total + num_events}
  end

  # ---------------------------------------------------------------------------
  # Composable Query Builders
  # ---------------------------------------------------------------------------

  defp count_events_query(filters) do
    base = base_events_query(Event, filters)

    case filters["endpoint_id"] do
      nil ->
        base

      endpoint_id ->
        from(e in base,
          join: s in Subscription,
          on:
            s.endpoint_id == ^endpoint_id and s.status == :enabled and s.topic_id == e.topic_id and
              e.inserted_at < s.inserted_at,
          join: ep in Endpoint,
          on:
            ep.id == ^endpoint_id and ep.consumer_id == e.consumer_id and
              ep.project_id == e.project_id and ep.status == :enabled
        )
    end
  end

  defp base_events_query(query, filters) do
    apply_filters(query, filters)
  end

  defp apply_filters(q, filters) do
    Enum.reduce(filters, q, fn {k, v}, q ->
      case k do
        "status" when is_list(v) and v != [] ->
          string_values = Enum.map(v, &to_string/1)

          if Enum.any?(string_values, &(&1 in @attempt_statuses)) do
            from(e in q,
              join: d in assoc(e, :delivery_attempts),
              where: d.status in ^string_values
            )
          else
            where(q, [e], e.status in ^string_values)
          end

        "status" when not is_nil(v) and v != "" ->
          str_val = to_string(v)

          if str_val in @attempt_statuses do
            from(e in q,
              join: d in assoc(e, :delivery_attempts),
              where: d.status == ^str_val
            )
          else
            where(q, [e], e.status == ^str_val)
          end

        "project_id" when not is_nil(v) and v != "" ->
          where(q, [e], e.project_id == ^to_string(v))

        "consumer_id" when not is_nil(v) and v != "" ->
          where(q, [e], e.consumer_id == ^to_string(v))

        "topic_id" when not is_nil(v) and v != "" ->
          where(q, [e], e.topic_id == ^to_string(v))

        "topic_ids" when is_list(v) and v != [] ->
          string_ids = Enum.map(v, &to_string/1)
          where(q, [e], e.topic_id in ^string_ids)

        "topic_ids" when is_binary(v) and v != "" ->
          where(q, [e], e.topic_id == ^v)

        "event_ids" when is_list(v) and v != [] ->
          string_ids = Enum.map(v, &to_string/1)
          where(q, [e], e.id in ^string_ids)

        key when key in ["inserted_after", "since"] ->
          case parse_date(v) do
            {val, fmt} ->
              where(q, [e], fragment("DATE_FORMAT(?, ?)", e.inserted_at, ^fmt) >= ^val)

            nil ->
              q
          end

        key when key in ["inserted_before", "until"] ->
          case parse_date(v) do
            {val, fmt} ->
              where(q, [e], fragment("DATE_FORMAT(?, ?)", e.inserted_at, ^fmt) <= ^val)

            nil ->
              q
          end

        _ ->
          q
      end
    end)
  end

  defp parse_date(nil), do: nil
  defp parse_date(""), do: nil

  defp parse_date(%DateTime{} = dt) do
    {Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S"), "%Y-%m-%d %H:%i:%s"}
  end

  defp parse_date(%Date{} = d) do
    {Calendar.strftime(d, "%Y-%m-%d"), "%Y-%m-%d"}
  end

  defp parse_date(dt_str) when is_binary(dt_str) do
    clean =
      dt_str
      |> String.trim()
      |> String.replace("T", " ")
      |> String.trim_trailing("Z")

    cond do
      Regex.match?(~r/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$/, clean) ->
        {clean, "%Y-%m-%d %H:%i"}

      Regex.match?(~r/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/, clean) ->
        {String.slice(clean, 0, 19), "%Y-%m-%d %H:%i:%s"}

      Regex.match?(~r/^\d{4}-\d{2}-\d{2}$/, clean) ->
        {clean, "%Y-%m-%d"}

      true ->
        nil
    end
  end

  defp parse_date(_), do: nil

  # ---------------------------------------------------------------------------
  # Parameter Normalization
  # ---------------------------------------------------------------------------

  defp normalize_params(params) when is_map(params) do
    Map.new(params, fn {k, v} -> {to_string(k), normalize_value(v)} end)
  end

  defp normalize_value(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp normalize_value(%Date{} = d), do: Date.to_iso8601(d)
  defp normalize_value(%TypeID{} = id), do: to_string(id)
  defp normalize_value(%Endpoint{id: id}), do: to_string(id)
  defp normalize_value(list) when is_list(list), do: Enum.map(list, &normalize_value/1)
  defp normalize_value(other), do: other

  defp parse_integer(val, _default) when is_integer(val), do: val

  defp parse_integer(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {n, _} -> n
      :error -> default
    end
  end

  defp parse_integer(_, default), do: default
end
