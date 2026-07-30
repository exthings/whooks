defmodule WhooksWorker.EventsWorker do
  alias BullMQ.Job

  alias Whooks.Events
  alias Whooks.Events.Event
  alias Whooks.Subscriptions
  alias Whooks.Topics
  alias Whooks.Repo

  require Logger

  def process(%Job{name: "create", data: data}) do
    Logger.info("[EventsWorker.create] creating: #{inspect(data)}")

    with {:ok, topic} <- get_topic(data["topic"], data["project_id"]),
         {:ok, event} <- insert_event(Map.put(data, "topic_id", topic.id)),
         {:ok, subscriptions} <- list_subscriptions(event),
         {:ok, _flow} <- add_flow(event, subscriptions),
         {:ok, event} <- Events.update_to_processing(event) do
      # Logger.info("[EventsWorker.create] Flow added: #{inspect(flow)}")
      {:ok, %{event_id: event.id, status: event.status}}
    end
  end

  def process(%Job{name: "update_status", data: %{"id" => id}} = job) do
    Logger.info("[EventsWorker.update_status] updating event id: #{inspect(id)}")

    with {:ok, children_values} <- BullMQ.Job.get_children_values(job),
         {:ok, ignored_failures} <- BullMQ.Job.get_ignored_children_failures(job),
         {:ok, pending_count} <- BullMQ.Job.get_dependencies_count(job) do
      delivery_results = Map.values(children_values)
      ignored_values = Map.values(ignored_failures)

      completed_count = length(delivery_results)
      ignored_count = length(ignored_values)
      total = completed_count + ignored_count + pending_count

      failed_count =
        Enum.count(delivery_results, fn
          %{"status" => "success"} -> false
          %{status: :success} -> false
          _ -> true
        end) + ignored_count

      event = Events.get_event!(id)

      update_event_status(event, failed_count, total)
    end
  end

  def process(%Job{name: name}) do
    {:error, "Unknown job type: #{name}"}
  end

  defp update_event_status(event, failed, total) when total > 0 and failed >= total do
    Logger.info("[EventsWorker.update_status] Event failed: #{inspect(event.id)}")
    event |> Events.update_to_failed() |> format_status_result()
  end

  defp update_event_status(event, 0, _total) do
    Logger.info("[EventsWorker.update_status] Event succeeded: #{inspect(event.id)}")
    event |> Events.update_to_success() |> format_status_result()
  end

  defp update_event_status(event, _failed, _total) do
    Logger.info("[EventsWorker.update_status] Event partial success: #{inspect(event.id)}")
    event |> Events.update_to_partial_success() |> format_status_result()
  end

  defp format_status_result({:ok, event}), do: {:ok, %{id: event.id}}
  defp format_status_result({:error, _} = error), do: error

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
         %Subscriptions.Subscription{} = subscription,
         %Events.Event{} = event
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
    topic = Topics.get_by_id!(topic_id)

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
end
