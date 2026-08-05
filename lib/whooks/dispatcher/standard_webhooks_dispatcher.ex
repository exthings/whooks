defmodule Whooks.Dispatcher.StandardWebhooksDispatcher do
  @behaviour Whooks.Dispatcher

  alias Whooks.Common.StandardWebhooks
  alias Whooks.Dispatcher.{Params, Result}

  require Logger

  @name :standard_webhooks

  @impl true
  def dispatch(%Params{} = params) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()

    url = Map.get(params.metadata, :url)
    secret = Map.get(params.metadata, :secret)

    data =
      StandardWebhooks.build_body(params.topic, timestamp, params.data)
      |> Jason.encode!()

    headers = build_headers(params.event_id, timestamp, data, secret)

    post(url, data, headers)
  end

  @impl true
  def result_to_attempt_params(%Result{response: nil} = result) do
    %{
      req_headers: %{},
      res_status: 500,
      res_body: %{error: result.error |> to_string()},
      res_headers: %{},
      latency_ms: 0
    }
  end

  @impl true
  def result_to_attempt_params(%Result{response: response}) do
    %{
      req_headers: response.private[:headers],
      res_status: response.status,
      res_body: parse_res_body(response.body),
      res_headers: response.headers,
      latency_ms: response.private[:latency_ms]
    }
  end

  defp req() do
    Req.new(
      headers: %{
        "accept" => "application/json",
        "content-type" => "application/json",
        "user-agent" => "whooks/#{Application.spec(:whooks, :vsn)}"
      }
    )
    |> Req.Request.append_request_steps(mark_start: &mark_start/1)
    |> Req.Request.append_response_steps(calc_latency: &calc_latency/1)
    |> Req.Request.append_response_steps(append_headers: &append_headers/1)
  end

  defp post(url, data, headers) do
    req()
    |> Req.post(base_url: url, body: data, headers: headers)
    |> handle_response()
  end

  defp build_headers(id, timestamp, data, secret) do
    signature = StandardWebhooks.sign(id, timestamp, data, secret)

    %{
      "webhook-id" => id,
      "webhook-timestamp" => timestamp,
      "webhook-signature" => signature
    }
  end

  defp mark_start(request) do
    request |> Req.Request.put_private(:start_time, System.monotonic_time())
  end

  defp calc_latency({request, response}) do
    end_time = System.monotonic_time()
    start_time = Req.Request.get_private(request, :start_time)
    duration = System.convert_time_unit(end_time - start_time, :native, :millisecond)
    response = Req.Response.put_private(response, :latency_ms, duration)
    {request, response}
  end

  defp append_headers({request, response}) do
    response = Req.Response.put_private(response, :headers, request.headers)
    {request, response}
  end

  defp handle_response({:ok, %Req.Response{status: status} = response})
       when status < 300 do
    {:ok, Result.success(response)}
  end

  defp handle_response({:ok, %Req.Response{status: status} = response})
       when status >= 300 do
    {:error, Result.failed(status, response)}
  end

  defp handle_response({:error, %Req.TransportError{reason: reason}}) do
    {:error, Result.failed(reason)}
  end

  defp parse_res_body(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, parsed} -> parsed
      {:error, _} -> %{generic: body}
    end
  end

  defp parse_res_body(body), do: body
end
