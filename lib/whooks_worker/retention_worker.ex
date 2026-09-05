defmodule WhooksWorker.RetentionWorker do
  @moduledoc """
  BullMQ worker processor for organization event retention purges.
  """

  alias BullMQ.Job
  alias Whooks.Events.Retention

  require Logger

  def process(%Job{name: "schedule_organization_purges"}) do
    Logger.info("[RetentionWorker] Scheduling organization retention purges")

    orgs = Retention.list_organizations_with_retention()

    for org <- orgs do
      BullMQ.Queue.add(
        "retention",
        "purge_organization",
        %{
          "organization_id" => org.id,
          "retention_days" => org.event_retention_days,
          "total_deleted" => 0
        },
        connection: :bullmq_redis
      )
    end

    {:ok, %{scheduled_count: length(orgs)}}
  end

  def process(%Job{name: "purge_organization", data: data}) do
    %{"organization_id" => org_id, "retention_days" => retention_days} = data
    batch_size = Map.get(data, "batch_size", 1_000)
    total_deleted = Map.get(data, "total_deleted", 0)

    {:ok, count} = Retention.purge_organization_events(org_id, retention_days, batch_size)

    if count > 0 do
      new_total = total_deleted + count

      BullMQ.Queue.add(
        "retention",
        "purge_organization",
        %{
          "organization_id" => org_id,
          "retention_days" => retention_days,
          "batch_size" => batch_size,
          "total_deleted" => new_total
        },
        delay: 1_000,
        connection: :bullmq_redis
      )

      Logger.info(
        "[Retention] Deleted #{count} events for org #{org_id} (running total: #{new_total}). Re-enqueued next batch with delay."
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
        "[Retention] Finished purge for org #{org_id}: #{total_deleted} total events deleted."
      )

      {:ok, %{organization_id: org_id, total_deleted: total_deleted, status: :completed}}
    end
  end

  def process(%Job{name: name}) do
    {:error, "Unknown job type: #{name}"}
  end
end
