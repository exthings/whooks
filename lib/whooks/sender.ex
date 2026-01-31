defmodule Whooks.Sender do
  require Logger

  def post(%{url: url, data: data, headers: headers}) do
    req()
    |> Req.post(base_url: url, json: data, headers: headers)
  end

  defp req() do
    Req.new(
      headers: %{
        "content-type" => "application/json",
        "user-agent" => "whooks/#{Application.spec(:whooks, :vsn)}"
      }
    )
    |> Req.Request.append_request_steps(mark_start: &mark_start/1)
    |> Req.Request.append_response_steps(calc_latency: &calc_latency/1)
  end

  defp mark_start(request) do
    # Store the start time in the private map
    request |> Req.Request.put_private(:start_time, System.monotonic_time())
  end

  defp calc_latency({request, response}) do
    end_time = System.monotonic_time()
    start_time = Req.Request.get_private(request, :start_time)
    duration = System.convert_time_unit(end_time - start_time, :native, :millisecond)
    response = Req.Response.put_private(response, :latency_ms, duration)
    {request, response}
  end
end
