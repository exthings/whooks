defmodule WhooksWorker.EventsWorker do
  alias BullMQ.Job

  alias Whooks.Events
  alias Whooks.Events.Event

  require Logger

  def process(%Job{name: "create", data: data}) do
    Logger.info("[EventsWorker.create] creating: #{inspect(data)}")

    case Events.create_with_attempts(data) do
      {:ok, %Event{} = event} ->
        {:ok, %{event_id: event.id, status: event.status}}

      {:error, reason} = error ->
        Logger.error("[EventsWorker.create] failed: #{inspect(reason)}")
        error
    end
  end

  def process(%Job{name: "resend", data: data}) do
    Logger.info("[EventsWorker.resend] resending: #{inspect(data)}")

    with {:ok, event} <- Events.get(data["id"]),
         {:ok, event} <- Events.resend_event(event) do
      {:ok, %{event_id: event.id, status: event.status}}
    end
  end

  def process(%Job{name: name}) do
    {:error, "Unknown job type: #{name}"}
  end
end
