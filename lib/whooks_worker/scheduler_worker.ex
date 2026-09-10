defmodule WhooksWorker.SchedulerWorker do
  @moduledoc """
  BullMQ worker processor for periodic and scheduled background jobs,
  including organization event retention purges and stalled event reconciliation.
  """

  alias BullMQ.Job
  alias Whooks.Events.Reconciler
  alias Whooks.Events.Retention

  require Logger

  def process(%Job{name: "schedule_organization_purges"}) do
    Logger.info("[SchedulerWorker] Scheduling organization retention purges")

    orgs = Retention.list_organizations_with_retention()

    jobs =
      orgs
      |> Enum.map(fn org ->
        {
          "purge_organization",
          %{
            "organization_id" => org.id,
            "retention_days" => org.event_retention_days,
            "total_deleted" => 0
          },
          []
        }
      end)

    # All jobs are added atomically - either all succeed or none do
    BullMQ.Queue.add_bulk("scheduler", jobs, connection: :bullmq_redis)
    |> case do
      {:ok, added_jobs} ->
        Logger.info(
          "[SchedulerWorker] Successfully registered #{length(added_jobs)} organization retention purges"
        )

        {:ok, %{scheduled_count: length(added_jobs)}}

      {:error, reason} ->
        Logger.warning(
          "[SchedulerWorker] Failed to register organization retention purges: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  def process(%Job{name: "purge_organization", data: data}) do
    %{"organization_id" => org_id, "retention_days" => retention_days} = data
    batch_size = Map.get(data, "batch_size", 1_000)
    total_deleted = Map.get(data, "total_deleted", 0)

    {:ok, count} = Retention.purge_organization_events(org_id, retention_days, batch_size)

    if count > 0 do
      new_total = total_deleted + count

      BullMQ.Queue.add(
        "scheduler",
        "purge_organization",
        %{
          "organization_id" => org_id,
          "retention_days" => retention_days,
          "batch_size" => batch_size,
          "total_deleted" => new_total
        },
        delay: 100,
        connection: :bullmq_redis
      )

      Logger.info(
        "[SchedulerWorker] Deleted #{count} events for org #{org_id} (running total: #{new_total}). Re-enqueued next batch with delay."
      )

      {:ok,
       %{
         organization_id: org_id,
         deleted_in_batch: count,
         total_deleted: new_total,
         status: :re_enqueued
       }}
    else
      Logger.info(
        "[SchedulerWorker] Finished purge for org #{org_id}: #{total_deleted} total events deleted."
      )

      {:ok, %{organization_id: org_id, total_deleted: total_deleted, status: :completed}}
    end
  end

  def process(%Job{name: "reconcile_stalled_events"}) do
    Logger.info("[SchedulerWorker] Running reconcile_stalled_events")
    Reconciler.reconcile()
  end

  def process(%Job{name: name}) do
    {:error, "Unknown job type: #{name}"}
  end
end
