defmodule WhooksWorker.EventsWorker do
  alias BullMQ.Job

  alias Whooks.Events
  alias Whooks.Events.Event
  alias Whooks.Subscriptions
  alias Whooks.Topics
  alias Whooks.Topics.Topic
  alias Whooks.Repo

  require Logger

  def process(%Job{name: "create", data: data}) do
    Logger.info("Create event: #{inspect(data)}")

    event_data =
      with {:ok, topic} <- get_topic(data["topic"], data["project_id"]) do
        data |> Map.put("topic_id", topic.id)
      end

    with {:ok, event} <- insert_event(event_data),
         {:ok, subscriptions} <- list_subscriptions(event),
         {:ok, flow} <- add_flow(event, subscriptions),
         {:ok, event} <- Events.update_to_processing(event) do
      Logger.info("Flow added: #{inspect(flow)}")
      {:ok, %{event_id: event.id, status: event.status}}
    end
  end

  def process(%Job{name: "update_status", data: %{"id" => id}} = job) do
    Logger.info("Update status event: #{inspect(id)}")

    {:ok, children_values} = BullMQ.Job.get_children_values(job)

    delivery_results = Map.values(children_values)
    total_deliveries = length(delivery_results)

    event = Events.get_event!(id)

    failed_count =
      Enum.count(delivery_results, fn
        %{"status" => "success"} -> false
        _ -> true
      end)

    cond do
      failed_count == 0 ->
        with {:ok, event} <- Events.update_to_success(event) do
          {:ok, %{id: event.id}}
        end

      failed_count == total_deliveries ->
        with {:ok, event} <- Events.update_to_failed(event) do
          {:ok, %{id: event.id}}
        end

      true ->
        with {:ok, event} <- Events.update_to_partial_success(event) do
          {:ok, %{id: event.id}}
        end
    end
  end

  def process(%Job{name: name}) do
    {:error, "Unknown job type: #{name}"}
  end

  defp insert_event(attrs) do
    %Event{}
    |> Event.create_changeset(attrs)
    |> Repo.insert()
  end

  defp list_subscriptions(%Event{} = event) do
    Subscriptions.list_by_topic(event.topic_id,
      consumer_id: event.consumer_id,
      project_id: event.project_id
    )
  end

  defp add_flow(%Event{} = event, subscription) do
    BullMQ.FlowProducer.add(
      %{
        queue_name: "events",
        name: "update_status",
        data: %{
          id: event.id
        },
        children: subscription |> Enum.map(&build_delivery_attempt_job(&1, event))
      },
      connection: :bullmq_redis
    )
  end

  defp build_delivery_attempt_job(
         %Subscriptions.Subscription{} = subscription,
         %Events.Event{} = event
       ) do
    id = "#{event.id}:#{subscription.id}"

    %{
      queue_name: "deliveries",
      name: "attempt",
      data: %{
        event_id: event.id,
        subscription_id: subscription.id,
        url: subscription.endpoint.url,
        headers: subscription.endpoint.headers,
        secret: subscription.endpoint.secret,
        topic: subscription.topic.name,
        data: event.data
      },
      opts: %{
        attempts: 3,
        backoff: %{type: :exponential, delay: 5_000},
        deduplication: %{id: id},
        fail_parent_on_failure: false,
        ignore_dependency_on_failure: true
      }
    }
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
