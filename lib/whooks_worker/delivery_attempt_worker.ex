defmodule WhooksWorker.DeliveryAttemptWorker do
  alias BullMQ.Job

  alias Whooks.DeliveryAttempts
  alias Whooks.DeliveryAttempts.DeliveryAttempt
  alias Whooks.Events
  alias Whooks.Serializer
  alias Whooks.Dispatcher.{Params, Result}

  require Logger

  def process(%Job{name: "attempt", data: data}) do
    Logger.info(
      "[DeliveryAttemptWorker.attempt] Processing event delivery_attempt: #{inspect(data)}"
    )

    event = Events.get_event!(data["event_id"])
    timestamp = DateTime.utc_now() |> DateTime.to_unix()

    dispatcher_module = Whooks.Dispatcher.get_dispatcher(:standard_webhooks)

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
    |> case do
      {:ok, %Result{} = result} ->
        attempt_params =
          dispatcher_module.result_to_attempt_params(result)
          |> Map.put(:event_id, event.id)
          |> Map.put(:subscription_id, data["subscription_id"])

        with {:ok, %DeliveryAttempt{} = attempt} <-
               DeliveryAttempts.create_success(attempt_params) do
          Logger.info("Event sent successfully: #{inspect(event.id)}")
          {:ok, Serializer.to_map(attempt)}
        end

      {:error, %Result{} = result} ->
        Logger.info("[DeliveryAttemptWorker.attempt] delivery failed: #{inspect(result)}")

        attempt_params =
          dispatcher_module.result_to_attempt_params(result)
          |> Map.put(:event_id, event.id)
          |> Map.put(:subscription_id, data["subscription_id"])

        with {:ok, attempt} <- DeliveryAttempts.create_failed(attempt_params) do
          {:error, %{failed: true}}
        else
          _ -> {:error, %{failed: true}}
        end
    end
  end

  def process(%Job{name: name}) do
    {:error, "Unknown job type: #{name}"}
  end
end
