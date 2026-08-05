defmodule Whooks.Events do
  @moduledoc """
  The Events context.
  """
  @behaviour Bodyguard.Policy

  use Nebulex.Caching

  import Ecto.Query, warn: false

  alias Whooks.Repo
  alias Whooks.Events.Event
  alias Whooks.Topics.Topic
  alias Whooks.Consumers.Consumer
  alias Whooks.Subscriptions.Subscription
  alias Whooks.DeliveryAttempts.DeliveryAttempt
  alias Whooks.Auth.Scope
  alias Whooks.RedisCache

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
    from(e in Event,
      where: e.id == ^id,
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
    |> apply_filters(opts)
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      event -> {:ok, event}
    end
  end

  def get!(id) do
    from(e in Event,
      where: e.id == ^id,
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
    |> Repo.one!()
  end

  @decorate cacheable(
              cache: RedisCache,
              key: &cache_key_gen/1,
              opts: [ttl: @idempotency_key_ttl]
            )
  def get_by_uid(uid) do
    from(e in Event,
      where: e.uid == ^uid,
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
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      event -> {:ok, event}
    end
  end

  def get_event!(id), do: Repo.get!(Event, id)

  def create_event(attrs) do
    Logger.info("Creating event: #{inspect(attrs)}")

    event_id = Event.gen_id() |> TypeID.to_string()
    attrs = Map.put(attrs, "id", event_id)

    get_by_uid(attrs["uid"])
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

  defp cache_key_gen(%{args: args} = ctx) do
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
