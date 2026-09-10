defmodule Whooks.Events.Reconciler do
  @moduledoc """
  Reconciles stalled events that failed to process or complete their flows.
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
  1. Stalled :pending events older than threshold:
     - If zero subscriptions: mark as :no_subscribers
     - If subscriptions exist: re-enqueue via Events.resend/1
  """
  def reconcile(opts \\ []) do
    threshold = Keyword.get(opts, :threshold_seconds, @default_threshold_seconds)
    cutoff = DateTime.utc_now() |> DateTime.add(-threshold, :second)

    stalled_pending_query =
      from(e in Event,
        where: e.status == :pending and e.inserted_at < ^cutoff,
        preload: [:topic]
      )

    stalled_events = Repo.all(stalled_pending_query)

    reconciled =
      Enum.reduce(stalled_events, 0, fn event, acc ->
        case Subscriptions.list_by_topic(event.topic_id,
               consumer_id: event.consumer_id,
               project_id: event.project_id
             ) do
          {:ok, []} ->
            Logger.info(
              "[Reconciler] Event #{inspect(event.id)} has no subscriptions; moving to no_subscribers"
            )

            Events.update_to_no_subscribers(event)
            acc + 1

          {:ok, _subs} ->
            Logger.info("[Reconciler] Re-triggering stalled event #{inspect(event.id)}")
            Events.resend(event)
            acc + 1

          _ ->
            acc
        end
      end)

    {:ok, %{reconciled_count: reconciled}}
  end
end
