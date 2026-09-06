defmodule WhooksWorker.EventsWorker do
  alias BullMQ.Job
  alias Whooks.Events

  require Logger

  def process(%Job{name: "create", data: data}) do
    Logger.info("[EventsWorker.create] creating: #{inspect(data)}")
    Events.process_create(data)
  end

  def process(%Job{name: "resend", data: data}) do
    Logger.info("[EventsWorker.resend] resending: #{inspect(data)}")
    Events.process_resend(data)
  end

  def process(%Job{name: "update_status", data: %{"id" => id}} = job) do
    Logger.info("[EventsWorker.update_status] updating event id: #{inspect(id)}")

    with {:ok, children_values} <- Job.get_children_values(job),
         {:ok, ignored_failures} <- Job.get_ignored_children_failures(job),
         {:ok, pending_count} <- Job.get_dependencies_count(job) do
      Events.update_status_from_deliveries(
        id,
        Map.values(children_values),
        Map.values(ignored_failures),
        pending_count
      )
    end
  end

  def process(%Job{name: name}) do
    {:error, "Unknown job type: #{name}"}
  end
end
