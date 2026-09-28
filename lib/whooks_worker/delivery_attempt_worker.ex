defmodule WhooksWorker.DeliveryAttemptWorker do
  alias BullMQ.Job

  alias Whooks.Repo
  alias Whooks.DeliveryAttempts
  alias Whooks.Events
  alias Whooks.Serializer
  alias Whooks.Dispatcher.{Params, Result}

  require Logger

  def process(%Job{name: "attempt", data: data} = job) do
    Logger.info(
      "[DeliveryAttemptWorker.attempt] Processing event delivery_attempt: #{inspect(data)}"
    )

    case get_and_update_data(data["attempt_id"]) do
      {:discarded, attempt} ->
        Logger.info(
          "[DeliveryAttemptWorker.attempt] delivery attempt discarded: #{inspect(attempt.id)}"
        )

        {:ok, Serializer.to_map(attempt)}

      {:ok, delivery_data} ->
        dispatch_result = dispatch(delivery_data)
        process_dispatch_result(dispatch_result, delivery_data, job)
    end
  end

  def process(%Job{name: name}) do
    {:error, "Unknown job type: #{name}"}
  end

  defp get_and_update_data(attempt_id) do
    Repo.transaction(fn ->
      attempt = DeliveryAttempts.get!(attempt_id)
      subscription = attempt.subscription
      endpoint = subscription.endpoint
      topic = subscription.topic
      event = attempt.event

      if disabled?(subscription, endpoint) do
        {:ok, attempt} = DeliveryAttempts.update_to_discarded(attempt)
        Events.maybe_mark_event_processed(event.id)
        {:discarded, attempt}
      else
        # Mark attempt processing
        {:ok, attempt} = DeliveryAttempts.update_to_processing(attempt)

        {:ok, event} = Events.update_to_processing(event)

        {:ok,
         %{
           attempt: attempt,
           event: event,
           topic: topic,
           endpoint: endpoint,
           subscription: subscription
         }}
      end
    end)
    |> case do
      {:ok, result} -> result
      error -> error
    end
  end

  defp disabled?(subscription, endpoint) do
    (subscription && subscription.status == :disabled) or
      (endpoint && endpoint.status == :disabled)
  end

  defp dispatch(%{attempt: attempt, topic: topic, event: event, endpoint: endpoint}) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    dispatcher_module = Whooks.Dispatcher.get_dispatcher(:standard_webhooks)

    dispatcher_module.dispatch(%Params{
      event_id: attempt.event_id |> TypeID.to_string(),
      topic: topic.name,
      timestamp: timestamp,
      data: event.data,
      metadata: %{
        url: endpoint.url,
        secret: endpoint.secret
      }
    })
  end

  defp process_dispatch_result(
         {:ok, %Result{} = result},
         %{attempt: attempt, event: event},
         _job
       ) do
    Logger.info(
      "[DeliveryAttemptWorker.attempt] delivery success for attempt #{inspect(attempt.id)}"
    )

    dispatcher_module = Whooks.Dispatcher.get_dispatcher(:standard_webhooks)
    attempt_params = dispatcher_module.result_to_attempt_params(result)

    {:ok, updated_attempt} =
      Repo.transaction(fn ->
        {:ok, updated_attempt} = DeliveryAttempts.update_to_success(attempt, attempt_params)
        Events.maybe_mark_event_processed(event.id)
        updated_attempt
      end)

    Logger.info("Event attempt sent successfully: #{inspect(attempt.id)}")
    {:ok, Serializer.to_map(updated_attempt)}
  end

  defp process_dispatch_result(
         {:error, %Result{} = result},
         %{attempt: attempt},
         job
       ) do
    Logger.warning("[DeliveryAttemptWorker.attempt] delivery failed: #{inspect(attempt.id)}")
    dispatcher_module = Whooks.Dispatcher.get_dispatcher(:standard_webhooks)
    attempt_params = dispatcher_module.result_to_attempt_params(result)

    attempts_made = (job.attempts_made || 0) + 1

    max_attempts =
      Map.get(job.opts || %{}, "attempts") ||
        Map.get(job.opts || %{}, :attempts) ||
        3

    if attempts_made >= max_attempts do
      {:ok, _} = DeliveryAttempts.update_to_failed(attempt, attempt_params)
    else
      {:ok, _} = DeliveryAttempts.update_to_retry(attempt, attempt_params)
    end

    Events.maybe_mark_event_processed(attempt.event_id)
    {:error, %{failed: true}}
  end
end
