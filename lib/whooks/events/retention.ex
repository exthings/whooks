defmodule Whooks.Events.Retention do
  @moduledoc """
  Context module for managing event retention policies and executing
  batched deletion of aged events and cascading delivery attempts.
  """

  import Ecto.Query, warn: false
  alias Whooks.Repo
  alias Whooks.Organizations.Organization
  alias Whooks.Events.Event

  require Logger

  @doc """
  Lists all organizations with an active retention policy (event_retention_days > 0).
  """
  def list_organizations_with_retention do
    from(o in Organization,
      where: not is_nil(o.event_retention_days) and o.event_retention_days > 0
    )
    |> Repo.all()
  end

  @doc """
  Purges a batch of events older than retention_days for a specific organization.
  Returns `{:ok, count}` where count is the number of deleted events in this batch.
  """
  def purge_organization_events(organization_id, retention_days, batch_size \\ 1000) do
    cutoff = DateTime.add(DateTime.utc_now(), -retention_days, :day)

    batch_query =
      from(e in Event,
        join: p in assoc(e, :project),
        where: p.organization_id == ^organization_id and e.inserted_at < ^cutoff,
        select: e.id,
        limit: ^batch_size
      )

    {count, _} =
      Repo.delete_all(from(e in Event, where: e.id in subquery(batch_query)))

    {:ok, count}
  end

  @doc """
  Upserts the hourly repeatable BullMQ job scheduler for event retention.
  """
  def setup_scheduler do
    case BullMQ.JobScheduler.upsert(
           :bullmq_redis,
           "retention",
           "hourly_retention_scheduler",
           %{pattern: "0 * * * *"},
           "schedule_organization_purges",
           %{},
           prefix: "bull"
         ) do
      {:ok, job} ->
        Logger.info("[Retention] Hourly retention scheduler registered: #{inspect(job.id)}")
        {:ok, job}

      {:error, reason} ->
        Logger.warning(
          "[Retention] Failed to register hourly retention scheduler: #{inspect(reason)}"
        )

        {:error, reason}
    end
  rescue
    e ->
      Logger.warning("[Retention] Could not setup scheduler: #{inspect(e)}")
      {:error, e}
  end
end
