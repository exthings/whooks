defmodule Whooks.Events do
  @moduledoc """
  The Events context.
  """

  import Ecto.Query, warn: false
  alias Whooks.Repo

  alias Whooks.Events.Event

  alias Whooks.Topics
  alias Whooks.Topics.Topic
  alias Whooks.Projects.Project
  alias Whooks.Consumers.Consumer
  alias Whooks.Subscriptions.Subscription
  alias Whooks.DeliveryAttempts.DeliveryAttempt

  require Logger

  @doc """
  Returns the list of events.

  ## Examples

      iex> list_events()
      [%Event{}, ...]

  """
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
      left_join: d in DeliveryAttempt,
      as: :delivery_attempt,
      on: e.id == d.event_id,
      preload: [:topic, :consumer, :delivery_attempts]
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

  # def get(id) do
  #   from(e in Event,
  #     where: e.id == ^id,
  #     join: t in Topic,
  #     on: e.topic_id == t.id,
  #     join: p in Project,
  #     on: e.project_id == p.id,
  #     join: c in Consumer,
  #     on: e.consumer_id == c.id,
  #     join: d in DeliveryAttempt,
  #     on: e.id == d.event_id,
  #     preload: [:topic, :project, :consumer, :delivery_attempts]
  #   )
  #   |> Repo.one()
  #   |> case do
  #     nil ->
  #       {:error, :not_found}

  #     event ->
  #       {:ok, event}
  #   end
  # end

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

  @doc """
  Gets a single event.

  Raises `Ecto.NoResultsError` if the Event does not exist.

  ## Examples

      iex> get_event!(123)
      %Event{}

      iex> get_event!(456)
      ** (Ecto.NoResultsError)

  """
  def get_event!(id), do: Repo.get!(Event, id)

  @doc """
  Creates a event.

  ## Examples

      iex> create_event(%{field: value})
      {:ok, %Event{}}

      iex> create_event(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_event(attrs) do
    Logger.info("Creating event: #{inspect(attrs)}")

    event_data =
      attrs["topic"]
      |> case do
        "topic_" <> _ = topic_id ->
          {:error, :invalid_topic}

        topic_name ->
          with {:ok, topic} <- get_topic(topic_name, attrs["project_id"]) do
            attrs |> Map.put("topic_id", topic.id)
          end
      end

    with {:ok, event} <- save_event(event_data),
         {:ok, _} <- enqueue_event(event) do
      {:ok, event}
    end
  end

  def update_to_scheduled(%Event{} = event) do
    event
    |> Event.update_changeset(%{status: :scheduled})
    |> Repo.update()
  end

  def update_to_scheduled(id) do
    from(e in Event, where: e.id == ^id)
    |> Repo.update_all(set: [status: :scheduled])
  end

  def update_to_processing(%Event{} = event) do
    event
    |> Event.update_changeset(%{status: :processing})
    |> Repo.update()
  end

  def update_to_processing(id) do
    from(e in Event, where: e.id == ^id)
    |> Repo.update_all(set: [status: :processing])
  end

  def update_to_success(%Event{} = event) do
    event
    |> Event.update_changeset(%{status: :success})
    |> Repo.update()
  end

  def update_to_success(id) do
    Logger.info("update_to_success: #{inspect(id)}")

    from(e in Event, where: e.id == ^id)
    |> Repo.update_all(set: [status: :success])
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

  defp save_event(attrs) do
    %Event{}
    |> Event.create_changeset(attrs)
    |> Repo.insert()
  end

  defp enqueue_event(%Event{} = event) do
    Logger.info("Enqueuing event: #{inspect(event.id)}")

    {:ok, job} =
      BullMQ.Queue.add("events", "created", %{id: event.id}, connection: :bullmq_redis)

    Logger.info("Job added: #{inspect(job.id)}")

    {:ok, event}
  end

  defp get_topic("topic_" <> _ = topic_id, project_id) do
    with %Topic{} = topic <- Topics.get_by_id!(topic_id) do
      (topic.project_id |> TypeID.to_string() ==
         project_id)
      |> case do
        true ->
          {:ok, topic}

        false ->
          {:error, :not_found}
      end
    end
  end

  defp get_topic(topic_name, project_id) do
    with %Topic{} = topic <- Topics.get_by_name!(topic_name, project_id) do
      (topic.project_id |> TypeID.to_string() ==
         project_id)
      |> case do
        true ->
          {:ok, topic}

        false ->
          {:error, :not_found}
      end
    end
  end
end
