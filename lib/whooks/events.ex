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
  alias Whooks.LocalCache

  require Logger

  @idempotency_key_ttl :timer.hours(12)
  @idempotency_key_prefix "event:idempotency:"

  def list_events do
    Repo.all(Event)
  end

  def list(params, opts \\ []) do
    Logger.info("list events")

    from(e in Event,
      join: t in Topic,
      on: e.topic_id == t.id,
      as: :topic,
      join: c in Consumer,
      on: e.consumer_id == c.id,
      as: :consumer,
      preload: [:topic, :consumer]
    )
    |> apply_filters(opts)
    |> Flop.validate_and_run(params, for: Event)
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

    get(attrs["uid"])
    |> case do
      {:ok, %Event{} = event} ->
        {:ok, event}

      {:error, :not_found} ->
        with {:ok, job} <-
               BullMQ.Queue.add("events", "create", attrs,
                 connection: :bullmq_redis,
                 deduplication: %{id: event_id}
               ) do
          Logger.info("[BullMQ] events.create job added: #{inspect(job.id)}")
          {:ok, %{id: event_id, job_id: job.id}}
        end
    end
  end

  def create(attrs) do
    %Event{}
    |> Event.create_changeset(attrs)
    |> Repo.insert()
  end

  def resend(%Event{} = event) do
    Logger.info("Resending event: #{inspect(event)}")

    with {:ok, job} <-
           BullMQ.Queue.add("events", "resend", %{id: event.id}, connection: :bullmq_redis) do
      Logger.info("[BullMQ] events.resend job added: #{inspect(job.id)}")
      {:ok, %{id: event.id, job_id: job.id}}
    end
  end

  def process_create(data) do
    with {:ok, topic} <- get_topic(data["topic"], data["project_id"]) do
      with :ok <- validate_data(topic, data["data"]),
           {:ok, event} <- create(Map.put(data, "topic_id", topic.id)),
           {:ok, subscriptions} <- list_subscriptions(event),
           {:ok, _flow} <- add_flow(event, subscriptions),
           {:ok, event} <- update_to_processing(event) do
        {:ok, %{event_id: event.id, status: event.status}}
      else
        {:error, %JsonXema.ValidationError{} = error} ->
          with {:ok, event} <-
                 create(
                   Map.merge(data, %{
                     "status" => :failed,
                     "topic_id" => topic.id,
                     "metadata" => %{
                       "failed_reason" => Exception.message(error)
                     }
                   })
                 ) do
            {:ok, %{event_id: event.id, status: event.status}}
          end

        error ->
          error
      end
    end
  end

  def process_resend(data) do
    with {:ok, event} <- get(data["id"]),
         {:ok, subscriptions} <- list_subscriptions(event),
         {:ok, _flow} <- add_flow(event, subscriptions),
         {:ok, event} <- update_to_processing(event) do
      {:ok, %{event_id: event.id, status: event.status}}
    end
  end

  def update_status_from_deliveries(id, delivery_results, ignored_failures, pending_count) do
    completed_count = length(delivery_results)
    ignored_count = length(ignored_failures)
    total = completed_count + ignored_count + pending_count

    failed_count =
      Enum.count(delivery_results, fn
        %{"status" => "success"} -> false
        %{status: :success} -> false
        _ -> true
      end) + ignored_count

    event = get_event!(id)

    update_event_status(event, failed_count, total)
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
  def update_to_success(%Event{} = event) do
    event
    |> Event.update_changeset(%{status: :success})
    |> Repo.update()
  end

  @decorate cache_put(
              cache: RedisCache,
              key: &cache_key_gen/1,
              opts: [ttl: @idempotency_key_ttl]
            )
  def update_to_retry(%Event{} = event) do
    event
    |> Event.update_changeset(%{status: :retry})
    |> Repo.update()
  end

  @decorate cache_put(
              cache: RedisCache,
              key: &cache_key_gen/1,
              opts: [ttl: @idempotency_key_ttl]
            )
  def update_to_failed(%Event{} = event) do
    event
    |> Event.update_changeset(%{status: :failed})
    |> Repo.update()
  end

  @decorate cache_put(
              cache: RedisCache,
              key: &cache_key_gen/1,
              opts: [ttl: @idempotency_key_ttl]
            )
  def update_to_partial_success(%Event{} = event) do
    event
    |> Event.update_changeset(%{status: :partial_success})
    |> Repo.update()
  end

  defp apply_filters(q, opts) do
    Enum.reduce(opts, q, fn
      {:consumer_id, consumer_id}, q ->
        where(q, [e], e.consumer_id == ^consumer_id)

      {:project_id, project_id}, q ->
        where(q, [e], e.project_id == ^project_id)

      {:organization_id, organization_id}, q ->
        where(q, [], as(:consumer).organization_id == ^organization_id)

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

  defp update_event_status(event, failed, total) when total > 0 and failed >= total do
    Logger.info("[Events.update_status] Event failed: #{inspect(event.id)}")
    event |> update_to_failed() |> format_status_result()
  end

  defp update_event_status(event, 0, _total) do
    Logger.info("[Events.update_status] Event succeeded: #{inspect(event.id)}")
    event |> update_to_success() |> format_status_result()
  end

  defp update_event_status(event, _failed, _total) do
    Logger.info("[Events.update_status] Event partial success: #{inspect(event.id)}")
    event |> update_to_partial_success() |> format_status_result()
  end

  defp format_status_result({:ok, event}), do: {:ok, %{id: event.id}}
  defp format_status_result({:error, _} = error), do: error

  defp list_subscriptions(%Event{} = event) do
    Subscriptions.list_by_topic(event.topic_id,
      consumer_id: event.consumer_id,
      project_id: event.project_id
    )
  end

  defp add_flow(%Event{} = event, subscriptions) do
    children = Enum.map(subscriptions, &build_delivery_attempt_job(&1, event))

    BullMQ.FlowProducer.add(
      %{
        queue_name: "events",
        name: "update_status",
        data: %{id: event.id |> TypeID.to_string()},
        children: children,
        opts: %{}
      },
      connection: :bullmq_redis
    )
  end

  defp build_delivery_attempt_job(
         %Subscription{} = subscription,
         %Event{} = event
       ) do
    %{
      queue_name: "deliveries",
      name: "attempt",
      data: %{
        event_id: event.id |> TypeID.to_string(),
        subscription_id: subscription.id |> TypeID.to_string(),
        url: subscription.endpoint.url,
        headers: subscription.endpoint.headers,
        secret: subscription.endpoint.secret,
        topic: subscription.topic.name,
        data: event.data
      },
      opts: %{
        attempts: 3,
        backoff: %{type: :exponential, delay: 5_000},
        fail_parent_on_failure: false,
        ignore_dependency_on_failure: true
      }
    }
  end

  defp get_topic("topic_" <> _ = topic_id, project_id) do
    topic = Topics.get!(topic_id)

    if TypeID.to_string(topic.project_id) == project_id do
      {:ok, topic}
    else
      {:error, :not_found}
    end
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
  end

  defp get_topic(topic_name, project_id) do
    {:ok, Topics.get_by_name!(topic_name, project_id)}
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
  end

  defp validate_data(topic, data) do
    if topic.validate_schema do
      schema = get_schema!(topic.id, topic.json_schema)
      JsonXema.validate(schema, data)
    else
      :ok
    end
  end

  defp get_schema!(topic_id, schema) do
    LocalCache.get_or_store!("schemas:#{topic_id}", fn ->
      JsonXema.new(schema)
    end)
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
