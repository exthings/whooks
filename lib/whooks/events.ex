defmodule Whooks.Events do
  @moduledoc """
  The Events context.
  """
  @behaviour Bodyguard.Policy

  use Nebulex.Caching

  import Ecto.Query, warn: false

  alias Whooks.Repo
  alias Whooks.Events.Event
  alias Whooks.Topics
  alias Whooks.Topics.Topic
  alias Whooks.Consumers.Consumer
  alias Whooks.Subscriptions
  alias Whooks.Subscriptions.Subscription
  alias Whooks.DeliveryAttempts.DeliveryAttempt
  alias Whooks.Endpoints.Endpoint
  alias Whooks.Auth.Scope
  alias Whooks.RedisCache
  alias Whooks.Common.Utils

  require Logger

  @idempotency_key_ttl :timer.hours(12)
  @idempotency_key_prefix "event:idempotency:"

  def list_events do
    Repo.all(Event)
  end

  def list(params, opts \\ []) do
    with {:ok, flop} <- Flop.validate(params, for: Event) do
      from(e in Event,
        join: t in Topic,
        on: e.topic_id == t.id,
        as: :topic,
        join: c in Consumer,
        on: e.consumer_id == c.id,
        as: :consumer,
        preload: [:topic, :consumer]
      )
      |> apply_filters(opts, flop)
      |> Flop.run(flop, for: Event)
      |> case do
        {data, meta} -> {:ok, {data, meta}}
      end
    end
  end

  def list_by_endpoint(params, endpoint_id) do
    from(e in Event,
      join: t in Topic,
      on: e.topic_id == t.id,
      join: d in DeliveryAttempt,
      on: e.id == d.event_id,
      join: s in Subscription,
      on: d.subscription_id == s.id,
      join: c in Consumer,
      on: e.consumer_id == c.id,
      where: s.endpoint_id == ^endpoint_id,
      preload: [:topic, :consumer]
    )
    |> Flop.validate_and_run(params, for: Event)
  end

  def get(id, opts \\ []) do
    event_query(id)
    |> apply_filters(opts)
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      event -> {:ok, event}
    end
  end

  def get!(id) do
    event_query(id)
    |> Repo.one!()
  end

  defp event_query("event_" <> _ = id) do
    where(event_base_query(), [e], e.id == ^id)
  end

  defp event_query(%TypeID{prefix: "event"} = id) do
    where(event_base_query(), [e], e.id == ^id)
  end

  defp event_query(uid) do
    where(event_base_query(), [e], e.uid == ^uid)
  end

  defp event_base_query do
    from(e in Event,
      left_join: t in assoc(e, :topic),
      as: :topic,
      left_join: p in assoc(e, :project),
      as: :project,
      left_join: c in assoc(e, :consumer),
      as: :consumer,
      left_join: d in assoc(e, :delivery_attempts),
      as: :delivery_attempt,
      left_join: s in assoc(d, :subscription),
      as: :subscription,
      left_join: ep in assoc(s, :endpoint),
      as: :endpoint,
      order_by: [desc: d.inserted_at],
      preload: [
        topic: t,
        project: p,
        consumer: c,
        delivery_attempts: {d, subscription: {s, endpoint: ep}}
      ]
    )
  end

  def get_event!(id), do: Repo.get!(Event, id)

  def enqueue(attrs) do
    Logger.info("Creating event: #{inspect(attrs)}")

    event_id = Event.gen_id() |> TypeID.to_string()
    attrs = Map.put(attrs, "id", event_id)
    uid = Map.get(attrs, "uid")
    has_uid = is_binary(uid) and String.trim(uid) != ""

    if has_uid do
      get(uid)
      |> case do
        {:ok, %Event{} = event} ->
          {:ok, event}

        {:error, :not_found} ->
          with {:ok, job} <-
                 BullMQ.Queue.add("events", "create", attrs,
                   connection: :bullmq_redis,
                   deduplication: %{id: uid || event_id}
                 ) do
            Logger.info("[BullMQ] events.create job added with uid dedup: #{inspect(job.id)}")
            {:ok, %{id: event_id, job_id: job.id}}
          end
      end
    else
      with {:ok, job} <-
             BullMQ.Queue.add("events", "create", attrs,
               connection: :bullmq_redis,
               deduplication: %{id: event_id}
             ) do
        Logger.info("[BullMQ] events.create job added with fallback dedup: #{inspect(job.id)}")
        {:ok, %{id: event_id, job_id: job.id}}
      end
    end
  end

  def create(attrs) do
    %Event{}
    |> Event.create_changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, event} ->
        {:ok, event}

      {:error, %Ecto.Changeset{errors: errors}} = error ->
        is_duplicate =
          Keyword.has_key?(errors, :uid) or Keyword.has_key?(errors, :id)

        if is_duplicate do
          uid = attrs["uid"] || Map.get(attrs, :uid)
          id = attrs["id"] || Map.get(attrs, :id)

          cond do
            is_binary(id) and String.trim(id) != "" -> get(id)
            is_binary(uid) and String.trim(uid) != "" -> get(uid)
            true -> error
          end
        else
          error
        end
    end
  end

  def create_with_attempts(attrs) do
    topic_param = attrs["topic"] || attrs[:topic] || attrs["topic_id"] || attrs[:topic_id]
    project_id = attrs["project_id"] || attrs[:project_id]
    data = attrs["data"] || attrs[:data] || %{}
    uid = attrs["uid"] || attrs[:uid]

    has_uid = is_binary(uid) and String.trim(uid) != ""

    if has_uid do
      case get(uid) do
        {:ok, %Event{} = existing_event} ->
          {:ok, existing_event}

        {:error, :not_found} ->
          do_create_with_attempts(attrs, topic_param, project_id, data)
      end
    else
      do_create_with_attempts(attrs, topic_param, project_id, data)
    end
  end

  defp do_create_with_attempts(attrs, topic_param, project_id, data) do
    with {:ok, topic} <- resolve_topic(topic_param, project_id) do
      case validate_payload(topic, data) do
        :ok ->
          attrs =
            attrs
            |> to_string_key_map()
            |> Map.put("topic_id", topic.id)
            |> Map.put_new_lazy("uid", fn -> Event.gen_id() |> TypeID.to_string() end)

          Repo.transaction(fn ->
            case create(attrs) do
              {:ok, %Event{} = event} ->
                case list_subscriptions(event) do
                  {:ok, []} ->
                    {:ok, event} = update_to_unprocessed(event)
                    {event, []}

                  {:ok, subscriptions} ->
                    attempts =
                      Enum.map(subscriptions, fn sub ->
                        attempt_id = DeliveryAttempt.gen_id() |> TypeID.to_string()

                        %{
                          id: attempt_id,
                          event_id: event.id,
                          subscription_id: sub.id,
                          status: :scheduled,
                          subscription: sub
                        }
                      end)

                    inserted_attempts =
                      Enum.map(attempts, fn attempt_data ->
                        {:ok, attempt} =
                          %DeliveryAttempt{}
                          |> DeliveryAttempt.create_changeset(
                            Map.drop(attempt_data, [:subscription])
                          )
                          |> Repo.insert()

                        Map.put(attempt, :subscription, attempt_data.subscription)
                      end)

                    {event, inserted_attempts}
                end

              {:error, changeset} ->
                Repo.rollback(changeset)
            end
          end)
          |> case do
            {:ok, {event, []}} ->
              {:ok, event}

            {:ok, {event, attempts}} ->
              enqueue_delivery_attempt_jobs(event, attempts)
              {:ok, event}

            {:error, reason} ->
              {:error, reason}
          end

        {:error, %JsonXema.ValidationError{} = error} ->
          metadata =
            (attrs["metadata"] || attrs[:metadata] || %{})
            |> Map.put("failed_reason", Exception.message(error))

          attrs =
            attrs
            |> to_string_key_map()
            |> Map.put("topic_id", topic.id)
            |> Map.put("status", :unprocessed)
            |> Map.put("metadata", metadata)
            |> Map.put_new_lazy("uid", fn -> Event.gen_id() |> TypeID.to_string() end)

          create(attrs)
      end
    end
  end

  def maybe_mark_event_processed(event_id) do
    pending_attempts =
      from(d in DeliveryAttempt,
        where: d.event_id == ^event_id and d.status in [:scheduled, :processing, :retry]
      )
      |> Repo.aggregate(:count)

    if pending_attempts == 0 do
      case get_event!(event_id) do
        %Event{status: status} = event when status != :processed ->
          update_to_processed(event)

        _ ->
          :ok
      end
    else
      :ok
    end
  end

  def list_subscriptions(%Event{} = event) do
    Subscriptions.list_by_topic(event.topic_id,
      consumer_id: event.consumer_id,
      project_id: event.project_id
    )
  end

  defp enqueue_delivery_attempt_jobs(%Event{} = event, attempts) do
    jobs =
      Enum.map(attempts, fn attempt ->
        sub = attempt.subscription

        {
          "attempt",
          %{
            "attempt_id" => to_string(attempt.id),
            "event_id" => to_string(event.id),
            "subscription_id" => to_string(sub.id),
            "url" => sub.endpoint.url,
            "headers" => sub.endpoint.headers,
            "secret" => sub.endpoint.secret,
            "topic" => sub.topic.name,
            "data" => event.data
          },
          [
            attempts: 3,
            backoff: %{type: :exponential, delay: 5_000}
          ]
        }
      end)

    BullMQ.Queue.add_bulk("deliveries", jobs, connection: :bullmq_redis)
  end

  defp resolve_topic(topic_or_id, project_id) do
    cond do
      is_nil(topic_or_id) ->
        {:error, :topic_required}

      is_binary(topic_or_id) and String.starts_with?(topic_or_id, "topic_") ->
        try do
          topic = Topics.get!(topic_or_id)

          if is_nil(project_id) or to_string(topic.project_id) == to_string(project_id) do
            {:ok, topic}
          else
            {:error, :not_found}
          end
        rescue
          Ecto.NoResultsError -> {:error, :not_found}
        end

      is_struct(topic_or_id, TypeID) ->
        try do
          topic = Topics.get!(topic_or_id)

          if is_nil(project_id) or to_string(topic.project_id) == to_string(project_id) do
            {:ok, topic}
          else
            {:error, :not_found}
          end
        rescue
          Ecto.NoResultsError -> {:error, :not_found}
        end

      is_binary(topic_or_id) ->
        try do
          if project_id do
            {:ok, Topics.get_by_name!(topic_or_id, project_id)}
          else
            {:ok, Topics.get_by_name!(topic_or_id)}
          end
        rescue
          Ecto.NoResultsError -> {:error, :not_found}
        end

      true ->
        {:error, :invalid_topic}
    end
  end

  defp validate_payload(%Topic{validate_schema: true, json_schema: schema} = topic, data)
       when not is_nil(schema) do
    compiled_schema =
      Whooks.LocalCache.get_or_store!("schemas:#{topic.id}", fn ->
        JsonXema.new(schema)
      end)

    case JsonXema.validate(compiled_schema, data) do
      :ok -> :ok
      {:error, error} -> {:error, error}
    end
  end

  defp validate_payload(_topic, _data), do: :ok

  defp to_string_key_map(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} -> {k, v}
    end)
  end

  def resend(%Event{} = event) do
    Logger.info("Resending event: #{inspect(event)}")

    with {:ok, job} <-
           BullMQ.Queue.add("events", "resend", %{id: event.id}, connection: :bullmq_redis) do
      Logger.info("[BullMQ] events.resend job added: #{inspect(job.id)}")
      {:ok, %{id: event.id, job_id: job.id}}
    end
  end

  def resend_event(%Event{} = event) do
    with {:ok, subscriptions} <- list_subscriptions(event) do
      case subscriptions do
        [] ->
          {:ok, event} = update_to_unprocessed(event)
          {:ok, event}

        subscriptions ->
          Repo.transaction(fn ->
            attempts =
              Enum.map(subscriptions, fn sub ->
                attempt_id = DeliveryAttempt.gen_id() |> TypeID.to_string()

                {:ok, attempt} =
                  %DeliveryAttempt{}
                  |> DeliveryAttempt.create_changeset(%{
                    id: attempt_id,
                    event_id: event.id,
                    subscription_id: sub.id,
                    status: :scheduled
                  })
                  |> Repo.insert()

                Map.put(attempt, :subscription, sub)
              end)

            {:ok, event} = update_to_processing(event)
            {event, attempts}
          end)
          |> case do
            {:ok, {event, attempts}} ->
              enqueue_delivery_attempt_jobs(event, attempts)
              {:ok, event}

            {:error, reason} ->
              {:error, reason}
          end
      end
    end
  end

  @doc """
  Resends multiple events in batches by adding jobs to BullMQ in bulk.
  Accepts a list of %Event{} structs, string IDs, or TypeIDs.
  """
  def resend_batch(events_or_ids, opts \\ [])

  def resend_batch([], _opts), do: {:ok, %{total_enqueued: 0, job_ids: []}}

  def resend_batch(events_or_ids, opts) when is_list(events_or_ids) do
    Logger.info(
      "[Events.resend_batch] events_or_ids count: #{length(events_or_ids)}, opts: #{inspect(opts)}"
    )

    batch_size = Keyword.get(opts, :batch_size, 5_000)

    event_ids =
      events_or_ids
      |> Enum.map(&extract_event_id/1)
      |> Enum.reject(&is_nil/1)

    if Enum.empty?(event_ids) do
      {:ok, %{total_enqueued: 0, job_ids: []}}
    else
      chunks = Enum.chunk_every(event_ids, batch_size)

      result =
        Enum.reduce_while(chunks, {:ok, {0, []}}, fn chunk, {:ok, {acc_count, acc_job_ids}} ->
          jobs = Enum.map(chunk, fn id -> {"resend", %{id: id}, []} end)

          case BullMQ.Queue.add_bulk("events", jobs, connection: :bullmq_redis) do
            {:ok, enqueued_jobs} ->
              count = length(enqueued_jobs)
              job_ids = Enum.map(enqueued_jobs, &to_string(&1.id))
              Logger.info("[BullMQ] events.resend_batch enqueued #{count} jobs")
              {:cont, {:ok, {acc_count + count, acc_job_ids ++ job_ids}}}

            {:error, reason} = err ->
              Logger.error("[BullMQ] events.resend_batch failed: #{inspect(reason)}")
              {:halt, err}
          end
        end)

      case result do
        {:ok, {total, job_ids}} -> {:ok, %{total_enqueued: total, job_ids: job_ids}}
        error -> error
      end
    end
  end

  @doc """
  Retries failed events (events with delivery attempts in status :failed) using batch resend.
  Supports filtering by :project_id, :consumer_id, :topic_id, :inserted_after, :inserted_before, and :batch_size.
  """
  def retry_failed(opts \\ []) do
    statuses = Keyword.get(opts, :statuses, [:failed])
    batch_size = Keyword.get(opts, :batch_size, 1_000)

    query =
      from(e in Event,
        join: d in Whooks.DeliveryAttempts.DeliveryAttempt,
        on: d.event_id == e.id,
        where: d.status in ^statuses,
        distinct: true,
        select: e.id
      )
      |> apply_retry_filters(opts)

    event_ids = Repo.all(query)
    resend_batch(event_ids, batch_size: batch_size)
  end

  @doc """
  Retries missing events for an endpoint that were created before the endpoint's subscriptions.
  Finds events with status :no_subscribers, :success, or :pending matching the endpoint's consumer,
  project, and subscribed topics inserted before each subscription was created.
  """
  def retry_missing(endpoint_or_id, opts \\ [])

  def retry_missing(%Endpoint{} = endpoint, opts) do
    endpoint = Repo.preload(endpoint, subscriptions: :topic)
    do_retry_missing(endpoint, opts)
  end

  def retry_missing(endpoint_id, opts)
      when is_binary(endpoint_id) or is_struct(endpoint_id, TypeID) do
    case Repo.get(Endpoint, endpoint_id) do
      nil ->
        {:error, :endpoint_not_found}

      %Endpoint{} = endpoint ->
        endpoint = Repo.preload(endpoint, subscriptions: :topic)
        do_retry_missing(endpoint, opts)
    end
  end

  defp do_retry_missing(%Endpoint{subscriptions: []}, _opts) do
    {:ok, %{total_enqueued: 0}}
  end

  defp do_retry_missing(%Endpoint{subscriptions: subscriptions} = endpoint, opts) do
    batch_size = Keyword.get(opts, :batch_size, 1_000)

    conditions =
      Enum.reduce(subscriptions, nil, fn sub, acc ->
        cond_clause =
          dynamic([e], e.topic_id == ^sub.topic_id and e.inserted_at < ^sub.inserted_at)

        if acc, do: dynamic([e], ^acc or ^cond_clause), else: cond_clause
      end)

    query =
      from(e in Event,
        where: e.consumer_id == ^endpoint.consumer_id and e.project_id == ^endpoint.project_id,
        where: e.status in [:unprocessed, :processed, :pending],
        where: ^conditions,
        select: e.id
      )
      |> apply_retry_filters(opts)

    event_ids = Repo.all(query)
    resend_batch(event_ids, batch_size: batch_size)
  end

  @doc """
  Replays events matching the given filters (e.g. project_id, consumer_id, topic_ids, inserted_after, inserted_before).
  Can include events with any statuses or custom specified statuses.
  """
  def bulk_replay(opts \\ []) do
    Logger.info("[Events.bulk_replay] opts: #{inspect(opts)}")
    batch_size = Keyword.get(opts, :batch_size, 1_000)
    statuses = Keyword.get(opts, :statuses)

    query =
      from(e in Event, select: e.id)
      |> apply_bulk_statuses(statuses)
      |> apply_retry_filters(opts)

    event_ids = Repo.all(query)
    Logger.info("[Events.bulk_replay] Found #{length(event_ids)} events")
    resend_batch(event_ids, batch_size: batch_size)
  end

  defp apply_bulk_statuses(q, nil), do: q

  defp apply_bulk_statuses(q, statuses) when is_list(statuses),
    do: where(q, [e], e.status in ^statuses)

  defp extract_event_id(%Event{id: id}), do: to_string(id)
  defp extract_event_id(%TypeID{} = id), do: TypeID.to_string(id)
  defp extract_event_id(id) when is_binary(id), do: id
  defp extract_event_id(_), do: nil

  defp apply_retry_filters(q, opts) do
    Enum.reduce(opts, q, fn
      {:project_id, project_id}, q when not is_nil(project_id) ->
        where(q, [e], e.project_id == ^project_id)

      {:consumer_id, consumer_id}, q when not is_nil(consumer_id) ->
        where(q, [e], e.consumer_id == ^consumer_id)

      {:topic_id, topic_id}, q when not is_nil(topic_id) ->
        where(q, [e], e.topic_id == ^topic_id)

      {:topic_ids, topic_ids}, q when is_list(topic_ids) and topic_ids != [] ->
        where(q, [e], e.topic_id in ^topic_ids)

      {:inserted_after, %DateTime{} = dt}, q ->
        where(q, [e], e.inserted_at >= ^dt)

      {:inserted_after, dt_str}, q when is_binary(dt_str) and dt_str != "" ->
        case DateTime.from_iso8601(dt_str) do
          {:ok, dt, _} -> where(q, [e], e.inserted_at >= ^dt)
          _ -> q
        end

      {:inserted_before, %DateTime{} = dt}, q ->
        where(q, [e], e.inserted_at <= ^dt)

      {:inserted_before, dt_str}, q when is_binary(dt_str) and dt_str != "" ->
        case DateTime.from_iso8601(dt_str) do
          {:ok, dt, _} -> where(q, [e], e.inserted_at <= ^dt)
          _ -> q
        end

      _, q ->
        q
    end)
  end

  @decorate cache_put(
              cache: RedisCache,
              key: &cache_key_gen/1,
              opts: [ttl: @idempotency_key_ttl]
            )
  def update_to_scheduled(%Event{} = event) do
    event
    |> Event.update_changeset(%{status: :scheduled})
    |> Repo.update()
  end

  @decorate cache_put(
              cache: RedisCache,
              key: &cache_key_gen/1,
              opts: [ttl: @idempotency_key_ttl]
            )
  def update_to_pending(%Event{} = event) do
    event
    |> Event.update_changeset(%{status: :pending})
    |> Repo.update()
  end

  @decorate cache_put(
              cache: RedisCache,
              key: &cache_key_gen/1,
              opts: [ttl: @idempotency_key_ttl]
            )
  def update_to_processing(%Event{} = event) do
    event
    |> Event.update_changeset(%{status: :processing})
    |> Repo.update()
  end

  @decorate cache_put(
              cache: RedisCache,
              key: &cache_key_gen/1,
              opts: [ttl: @idempotency_key_ttl]
            )
  def update_to_processed(%Event{} = event) do
    event
    |> Event.update_changeset(%{status: :processed})
    |> Repo.update()
  end

  @decorate cache_put(
              cache: RedisCache,
              key: &cache_key_gen/1,
              opts: [ttl: @idempotency_key_ttl]
            )
  def update_to_unprocessed(%Event{} = event) do
    event
    |> Event.update_changeset(%{status: :unprocessed})
    |> Repo.update()
  end

  def update_to_no_subscribers(%Event{} = event), do: update_to_unprocessed(event)
  def update_to_success(%Event{} = event), do: update_to_processed(event)
  def update_to_partial_success(%Event{} = event), do: update_to_processed(event)
  def update_to_failed(%Event{} = event), do: update_to_processed(event)
  def update_to_retry(%Event{} = event), do: update_to_processing(event)

  defp apply_filters(q, opts, %Flop{} = flop) do
    Logger.info("apply filters flop")

    Enum.any?(flop.filters, fn f ->
      f.field in [:id, :uid, :tags]
    end)
    |> case do
      true ->
        opts = Keyword.drop(opts, [:last])
        apply_filters(q, opts)

      false ->
        apply_filters(q, opts)
    end
  end

  defp apply_filters(q, opts) do
    Enum.reduce(opts, q, fn
      {:consumer_id, consumer_id}, q ->
        where(q, [e], e.consumer_id == ^consumer_id)

      {:project_id, project_id}, q ->
        where(q, [e], e.project_id == ^project_id)

      {:organization_id, organization_id}, q ->
        where(q, [], as(:consumer).organization_id == ^organization_id)

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

  defp cache_key_gen(%{args: args}) do
    Logger.info("args #{inspect(args)}")

    uid =
      hd(args)
      |> case do
        id when is_binary(id) -> id
        event when is_map(event) -> Map.get(event, :uid)
        event when is_struct(event) -> event.uid
      end

    "#{@idempotency_key_prefix}#{uid}"
  end

  def authorize(:get, %Scope{user: user}, _opts) do
    user.role in [:root, :admin, :support]
  end

  def authorize(:list, %Scope{user: user}, _opts) do
    user.role in [:root, :admin, :support]
  end

  def authorize(:resend, %Scope{user: user}, _opts) do
    user.role in [:root, :admin, :support]
  end

  def authorize(:resend_batch, %Scope{user: user}, _opts) do
    user.role in [:root, :admin, :support]
  end

  def authorize(:retry_failed, %Scope{user: user}, _opts) do
    user.role in [:root, :admin, :support]
  end

  def authorize(:retry_missing, %Scope{user: user}, _opts) do
    user.role in [:root, :admin, :support]
  end

  def authorize(:bulk_replay, %Scope{user: user}, _opts) do
    user.role in [:root, :admin, :support]
  end

  def authorize(:create, %Scope{user: _user}, _opts) do
    false
  end

  def authorize(:update, %Scope{user: _user}, _opts) do
    false
  end

  def authorize(:delete, %Scope{user: _user}, _opts) do
    false
  end
end
