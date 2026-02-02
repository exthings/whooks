defmodule WhooksWorker.DeliveryAttemptWorker do
  alias BullMQ.Job

  alias Whooks.Sender
  alias Whooks.DeliveryAttempts
  alias Whooks.Events

  require Logger

  def process(%Job{name: "attempt", data: data}) do
    Logger.info("Processing delivery_attempt: #{inspect(data)}")

    payload = %{url: data["url"], data: data["data"], headers: data["headers"]}

    with {:ok, %Req.Response{} = response} <- Sender.post(payload),
         {:ok, attempt} <- DeliveryAttempts.create_success(prepare_attempt_data(data, response)),
         _ <- Events.update_to_success(data["event_id"]) do
      Logger.info("Delivery attempt created with success: #{inspect(attempt.id)}")
      {:ok, %{sent: true}}
    else
      {:error, reason} ->
        Logger.error("Delivery error")
        Logger.error(reason)
        {:error, reason}
    end
  end

  def process(%Job{name: name}) do
    {:error, "Unknown job type: #{name}"}
  end

  defp prepare_attempt_data(data, response) do
    Logger.info("prepare_attempt_data: #{inspect(response.body)}")

    %{
      res_status: response.status,
      res_body: parse_res_body(response.body),
      res_headers: response.headers,
      latency_ms: response.private[:latency_ms],
      event_id: data["event_id"],
      subscription_id: data["subscription_id"]
    }
  end

  defp parse_res_body(body) when is_binary(body) do
    body |> Jason.decode!()
  end

  defp parse_res_body(body) when is_map(body) do
    body
  end

  defp parse_res_body(body) when is_list(body) do
    body
  end
end
