defmodule WhooksWorker.DeliveryAttemptWorker do
  alias BullMQ.Job

  alias Whooks.Repo
  alias Whooks.DeliveryAttempts
  alias Whooks.DeliveryAttempts.DeliveryAttempt
  alias Whooks.Events
  alias Whooks.Events.Event
  alias Whooks.Serializer
  alias Whooks.Dispatcher.{Params, Result}

  require Logger

  def process(%Job{name: "attempt", data: data} = job) do
    Logger.info(
      "[DeliveryAttemptWorker.attempt] Processing event delivery_attempt: #{inspect(data)}"
    )

    attempt_id = data["attempt_id"]

    attempt =
      case attempt_id do
        id when is_binary(id) and id != "" ->
          Repo.get!(DeliveryAttempt, id)

        _ ->
          attempt_id = DeliveryAttempt.gen_id() |> TypeID.to_string()

          {:ok, attempt} =
            %DeliveryAttempt{}
            |> DeliveryAttempt.create_changeset(%{
              id: attempt_id,
              event_id: data["event_id"],
              subscription_id: data["subscription_id"],
              status: :scheduled
            })
            |> Repo.insert()

          attempt
      end

    # Mark attempt processing
    {:ok, attempt} = DeliveryAttempts.update_to_processing(attempt)

    # Ensure event is marked :processing
    case Events.get(data["event_id"]) do
      {:ok, %Event{status: status} = event} when status in [:pending, :scheduled] ->
        Events.update_to_processing(event)

      _ ->
        :ok
    end

    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    dispatcher_module = Whooks.Dispatcher.get_dispatcher(:standard_webhooks)

    dispatch_result =
      dispatcher_module.dispatch(%Params{
        event_id: data["event_id"],
        topic: data["topic"],
        timestamp: timestamp,
        data: data["data"],
        metadata: %{
          url: data["url"],
          secret: data["secret"]
        }
      })

    case dispatch_result do
      {:ok, %Result{} = result} ->
        attempt_params = dispatcher_module.result_to_attempt_params(result)

        {:ok, updated_attempt} = DeliveryAttempts.update_to_success(attempt, attempt_params)
        Events.maybe_mark_event_processed(data["event_id"])
        Logger.info("Event attempt sent successfully: #{inspect(attempt.id)}")
        {:ok, Serializer.to_map(updated_attempt)}

      {:error, %Result{} = result} ->
        Logger.info("[DeliveryAttemptWorker.attempt] delivery failed: #{inspect(result)}")
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

        Events.maybe_mark_event_processed(data["event_id"])
        {:error, %{failed: true}}
    end
  end

  def process(%Job{name: name}) do
    {:error, "Unknown job type: #{name}"}
  end
end
