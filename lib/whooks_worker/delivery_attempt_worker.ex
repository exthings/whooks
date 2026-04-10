defmodule WhooksWorker.DeliveryAttemptWorker do
  alias BullMQ.Job

  alias Whooks.Sender
  alias Whooks.DeliveryAttempts
  alias Whooks.DeliveryAttempts.DeliveryAttempt
  alias Whooks.Events
  alias Whooks.StandardWebhooks
  alias Whooks.Repo

  require Logger

  def process(%Job{name: "attempt", data: data}) do
    Logger.info("Processing event delivery_attempt: #{inspect(data)}")

    event = Events.get_event!(data["event_id"])
    id = DeliveryAttempt.gen_id()
    timestamp = DateTime.utc_now() |> DateTime.to_unix()

    payload_data =
      StandardWebhooks.build_body(data["topic"], timestamp, data["data"])
      |> Jason.encode!()

    headers = build_headers(id, timestamp, payload_data, data)
    request = %{url: data["url"], data: payload_data, headers: headers}

    with {:ok, event} <- Events.update_to_processing(event),
         {:ok, response} <- Sender.post(request) do
      handle_success(id, response, event, headers, data)
    else
      {:error, error} ->
        handle_failure(id, error, event, headers, data)
    end
  end

  def process(%Job{name: name}) do
    {:error, "Unknown job type: #{name}"}
  end

  defp handle_success(id, %Req.Response{} = response, event, headers, data) do
    attempt_params = %{
      id: id,
      req_headers: headers,
      res_status: response.status,
      res_body: parse_res_body(response.body),
      res_headers: response.headers,
      latency_ms: response.private[:latency_ms],
      event_id: data["event_id"],
      subscription_id: data["subscription_id"]
    }

    Repo.transact(fn ->
      {:ok, _attempt} = DeliveryAttempts.create_success(attempt_params)
      {:ok, _} = Events.update_to_success(event)

      Logger.info("Event sent successfully: #{inspect(event.id)}")
      {:ok, :sent}
    end)
  end

  defp handle_failure(id, error, event, headers, data) do
    attempt_params = %{
      id: id,
      req_headers: headers,
      res_status: 500,
      latency_ms: 0,
      event_id: data["event_id"],
      subscription_id: data["subscription_id"]
    }

    Repo.transact(fn ->
      {:ok, _attempt} = DeliveryAttempts.create_failed(attempt_params)
      {:ok, _} = Events.update_to_retry(event)

      Logger.info("Event failed: #{inspect(event.id)}")
      {:error, error}
    end)
  end

  defp build_headers(id, timestamp, payload_data, data) do
    id
    |> TypeID.to_string()
    |> build_standard_webhook_headers(timestamp, payload_data, data["secret"])
    |> Map.merge(Map.get(data, "headers", %{}))
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

  defp parse_res_body(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, parsed} -> parsed
      {:error, _} -> body
    end
  end

  defp parse_res_body(body), do: body
end
