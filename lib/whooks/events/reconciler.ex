defmodule Whooks.Events.Reconciler do
  @moduledoc """
  Reconciles stalled events that failed to process or complete their deliveries.
  """
  import Ecto.Query

  alias Whooks.Repo
  alias Whooks.Events
  alias Whooks.Events.Event
  alias Whooks.Subscriptions

  require Logger

  @default_threshold_seconds 300
  @scheduler_every_ms 300_000

  @doc """
  Upserts the 5-minute repeatable BullMQ job scheduler for stalled events reconciliation on the scheduler queue.
  """
  def setup_scheduler do
    # Clean up legacy repeatable scheduler on "events" queue if present
    BullMQ.JobScheduler.remove(:bullmq_redis, "events", "stalled_events_reconciler")

    case BullMQ.JobScheduler.upsert(
           :bullmq_redis,
           "scheduler",
           "stalled_events_reconciler",
           %{every: @scheduler_every_ms},
           "reconcile_stalled_events",
           %{},
           prefix: "bull"
         ) do
      {:ok, job} ->
        Logger.info(
          "[Reconciler] Stalled events reconciler scheduler registered: #{inspect(job.id)}"
        )

        {:ok, job}

      {:error, reason} ->
        Logger.warning("[Reconciler] Failed to register reconciler scheduler: #{inspect(reason)}")
        {:error, reason}
    end
  rescue
    e ->
      Logger.warning("[Reconciler] Exception registering reconciler scheduler: #{inspect(e)}")
      {:error, e}
  end

  @doc """
  Scans for stalled events and recovers them.
  - Events stuck in :pending or :processing older than threshold:
    1. If 0 delivery attempts:
       - If zero subscriptions: mark as :unprocessed
       - If subscriptions exist: re-enqueue via Events.resend_event/1
    2. If delivery attempts exist:
       - If all attempts are terminal (:success, :failed, :discarded): mark as :processed
       - If stalled attempts exist in :scheduled: re-enqueue missing BullMQ jobs
  """
  def reconcile(opts \\ []) do
    threshold = Keyword.get(opts, :threshold_seconds, @default_threshold_seconds)
    cutoff = DateTime.utc_now() |> DateTime.add(-threshold, :second)

    stalled_query =
      from(e in Event,
        where: e.status in [:pending, :processing] and e.inserted_at < ^cutoff,
        preload: [:topic, delivery_attempts: [subscription: [:endpoint, :topic]]]
      )

    stalled_events = Repo.all(stalled_query)

    reconciled_count =
      Enum.reduce(stalled_events, 0, fn event, count ->
        cond do
          # 1. Zero attempts created
          Enum.empty?(event.delivery_attempts) ->
            case Subscriptions.list_by_topic(event.topic_id,
                   consumer_id: event.consumer_id,
                   project_id: event.project_id
                 ) do
              {:ok, []} ->
                Logger.info(
                  "[Reconciler] Event #{inspect(event.id)} has no subscriptions; moving to unprocessed"
                )

                Events.update_to_unprocessed(event)
                count + 1

              {:ok, _subs} ->
                Logger.info(
                  "[Reconciler] Resending stalled event #{inspect(event.id)} with subscriptions"
                )

                case Events.resend_event(event) do
                  {:ok, _} -> count + 1
                  _ -> count
                end

              _ ->
                count
            end

          # 2. All attempts are terminal
          all_attempts_terminal?(event.delivery_attempts) ->
            Logger.info(
              "[Reconciler] Event #{inspect(event.id)} all attempts terminal; moving to processed"
            )

            Events.update_to_processed(event)
            count + 1

          # 3. Attempts stuck in :scheduled -> re-enqueue them
          has_stalled_scheduled_attempts?(event.delivery_attempts) ->
            stalled_scheduled =
              Enum.filter(event.delivery_attempts, &(&1.status == :scheduled))

            Logger.info(
              "[Reconciler] Re-enqueuing #{length(stalled_scheduled)} scheduled attempts for event #{inspect(event.id)}"
            )

            re_enqueue_attempts(event, stalled_scheduled)
            count + length(stalled_scheduled)

          true ->
            count
        end
      end)

    {:ok, %{reconciled_count: reconciled_count}}
  end

  defp all_attempts_terminal?([]), do: false

  defp all_attempts_terminal?(attempts) do
    Enum.all?(attempts, fn attempt ->
      attempt.status in [:success, :failed, :discarded]
    end)
  end

  defp has_stalled_scheduled_attempts?(attempts) do
    Enum.any?(attempts, fn attempt ->
      attempt.status == :scheduled
    end)
  end

  defp re_enqueue_attempts(event, attempts) do
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
end
