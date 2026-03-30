defmodule WhooksWorker.DeliveryAttemptWorker do
  alias BullMQ.Job

  alias Whooks.Sender
  alias Whooks.DeliveryAttempts
  alias Whooks.DeliveryAttempts.DeliveryAttempt
  alias Whooks.Events
  alias Whooks.StandardWebhooks

  require Logger

  def process(%Job{name: "attempt", data: data}) do
    Logger.info("Processing delivery_attempt: #{inspect(data)}")

    id = DeliveryAttempt.gen_id()
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    payload_data = data["data"] |> Jason.encode!()

    headers =
      build_standard_webhook_headers(
        id |> TypeID.to_string(),
        timestamp,
        payload_data,
        data["secret"]
      )
      |> Map.merge(Map.get(data, "headers", %{}))

    request = %{url: data["url"], data: payload_data, headers: headers}

    with {:ok, %Req.Response{} = response} <- Sender.post(request),
         {:ok, attempt} <-
           DeliveryAttempts.create_success(%{
             id: id,
             req_headers: headers,
             res_status: response.status,
             res_body: parse_res_body(response.body),
             res_headers: response.headers,
             latency_ms: response.private[:latency_ms],
             event_id: data["event_id"],
             subscription_id: data["subscription_id"]
           }),
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

  defp prepare_attempt_data(id, data, response) do
    %{
      id: id,
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

  defp build_standard_webhook_headers(id, timestamp, payload, secret) do
    Logger.info("Building standard webhook headers")

    signature = StandardWebhooks.sign(id, timestamp, payload, secret)

    %{
      "webhook-id" => id,
      "webhook-timestamp" => timestamp,
      "webhook-signature" => signature
    }
  end
end
