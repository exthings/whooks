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
  alias Whooks.Auth.Scope
  alias Whooks.RedisCache
  alias Whooks.Events.Bulk
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

  def get(id, opts \\ [])
  def get(nil, _opts), do: {:error, :not_found}
  def get("", _opts), do: {:error, :not_found}

  def get(id, opts) do
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

  def create_and_enqueue(attrs) do
    topic_id = Map.get(attrs, "topic")
    consumer_id = Map.get(attrs, "consumer_id")
    project_id = Map.get(attrs, "project_id")

    case find_existing_event(attrs) do
      {:ok, %Event{} = existing_event} ->
        {:ok, existing_event}

      _ ->
        with {:ok, topic} <-
               Topics.get_with_subscriptions(topic_id,
                 consumer_id: consumer_id,
                 project_id: project_id
               ),
             #  {:ok, event_attrs, should_dispatch?} <- validate_payload(topic, attrs),
             {:ok, {event, attempts}} <-
               insert_with_transaction(attrs, topic.subscriptions),
             {:ok, _} <- enqueue_attempts(event, attempts) do
          {:ok, event}
        end
    end
  end

  defdelegate create_with_attempts(attrs), to: __MODULE__, as: :create_and_enqueue

  defp find_existing_event(attrs) do
    uid = attrs["uid"] || attrs[:uid]

    case get(uid) do
      {:ok, %Event{}} = result -> result
      {:error, :not_found} -> :not_found
    end
  end

  defp insert_with_transaction(attrs, subscriptions = []) do
    Repo.transaction(fn ->
      case create(attrs) do
        {:ok, %Event{} = event} ->
          cond do
            subscriptions == [] ->
              {:ok, event} = update_to_unprocessed(event)
              {event, []}

            true ->
              attempts = insert_delivery_attempts(event, subscriptions)
              {event, attempts}
          end

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  defp insert_with_transaction(attrs, subscriptions) do
    sub = Enum.at(subscriptions, 0)
    subscriptions = Enum.filter(subscriptions, fn s -> s.status == :enabled end)
    attrs = Map.put(attrs, "topic_id", sub.topic_id)

    Repo.transaction(fn ->
      case create(attrs) do
        {:ok, %Event{} = event} ->
          if subscriptions == [] do
            {:ok, event} = update_to_unprocessed(event)
            {event, []}
          else
            attempts = insert_delivery_attempts(event, subscriptions)
            {event, attempts}
          end

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  defp insert_delivery_attempts(%Event{} = event, subscriptions) do
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
  end

  defp enqueue_attempts(_event, []), do: :ok

  defp enqueue_attempts(%Event{} = event, attempts) when is_list(attempts) do
    jobs =
      Enum.map(attempts, fn attempt ->
        DeliveryAttempt.build_bullmq_job(attempt.id)
      end)

    BullMQ.Queue.add_bulk("deliveries", jobs, connection: :bullmq_redis)
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

  defp validate_payload(%Topic{} = topic, attrs) when is_map(attrs) do
    data = attrs["data"] || attrs[:data] || %{}

    case check_payload_schema(topic, data) do
      :ok ->
        event_attrs = prepare_event_attrs(attrs, topic)
        {:ok, event_attrs, _should_dispatch? = true}

      {:error, %JsonXema.ValidationError{} = error} ->
        metadata =
          (attrs["metadata"] || attrs[:metadata] || %{})
          |> Map.put("failed_reason", Exception.message(error))

        event_attrs =
          prepare_event_attrs(attrs, topic, %{
            "status" => :unprocessed,
            "metadata" => metadata
          })

        {:ok, event_attrs, _should_dispatch? = false}
    end
  end

  defp check_payload_schema(%Topic{validate_schema: true, json_schema: schema} = topic, data)
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

  defp check_payload_schema(_topic, _data), do: :ok

  defp prepare_event_attrs(attrs, %Topic{} = topic, extra \\ %{}) do
    attrs
    |> to_string_key_map()
    |> Map.put("topic_id", topic.id)
    |> Map.put_new_lazy("uid", fn -> Event.gen_id() |> TypeID.to_string() end)
    |> Map.merge(extra)
  end

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

  def resend_event(event_or_id)

  def resend_event(event_id) when is_binary(event_id) or is_struct(event_id, TypeID) do
    case get(event_id) do
      {:ok, event} -> resend_event(event)
      error -> error
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
              enqueue_attempts(event, attempts)
              {:ok, event}

            {:error, reason} ->
              {:error, reason}
          end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Bulk Operations API
  # ---------------------------------------------------------------------------

  @doc """
  Replays past events based on filters (topic, consumer, date range, etc.).
  """
  defdelegate replay(params \\ %{}), to: Bulk

  @doc """
  Retries failed events (events that had failed delivery attempts).
  """
  defdelegate retry_failed(params \\ %{}), to: Bulk

  @doc """
  Retry missing events for an endpoint created before endpoint subscriptions.
  """
  defdelegate retry_missing(endpoint_or_id, params \\ %{}), to: Bulk

  @doc """
  Resends multiple specific events by IDs or Event structs.
  """
  defdelegate resend_events(events_or_ids, params \\ %{}), to: Bulk

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

  def authorize(action, %Scope{user: user}, _opts)
      when action in [
             :get,
             :list,
             :resend,
             :resend_events,
             :replay,
             :retry_failed,
             :retry_missing
           ] do
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
