defmodule WhooksWorker.EventsWorker do
  alias BullMQ.Job

  alias Whooks.Events
  alias Whooks.Subscriptions

  require Logger

  def process(%Job{name: "created", data: %{"id" => id}}) do
    Logger.info("Processing event_id: #{inspect(id)}")
    event = Events.get_event!(id)

    with {:ok, subscriptions} <-
           Subscriptions.list_by_topic(event.topic_id,
             consumer_id: event.consumer_id,
             project_id: event.project_id
           ) do
      Logger.info("Total subscriptions: #{length(subscriptions)}")

      jobs =
        subscriptions
        |> Enum.map(&prepare_delivery_attempt(&1, event))

      with {:ok, _} <- BullMQ.Queue.add_bulk("deliveries", jobs, connection: :bullmq_redis),
           {:ok, _} <- Events.update_to_scheduled(event) do
        {:ok, %{sent: true}}
      end
    end
  end

  def process(%Job{name: name}) do
    {:error, "Unknown job type: #{name}"}
  end

  defp prepare_delivery_attempt(subscription, event) do
    {
      "attempt",
      %{
        event_id: event.id,
        subscription_id: subscription.id,
        url: subscription.endpoint.url,
        headers: subscription.endpoint.headers,
        data: event.data
      },
      []
    }
  end
end
