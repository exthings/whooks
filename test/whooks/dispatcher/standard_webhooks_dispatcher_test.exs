defmodule Whooks.Dispatcher.StandardWebhooksDispatcherTest do
  use ExUnit.Case, async: true

  alias Whooks.Dispatcher.StandardWebhooksDispatcher
  alias Whooks.Dispatcher.{Params, Result}

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "dispatch/1 successful request", %{bypass: bypass} do
    res_data = %{status: "success"}

    Bypass.expect_once(bypass, "POST", "/v1/webhooks", fn conn ->
      Plug.Conn.resp(conn, 200, Jason.encode!(res_data))
    end)

    timestamp = DateTime.utc_now()

    params = %Params{
      event_id: "lcjinejt23v6njnpmlmgz7sl",
      topic: "transaction.paid",
      data: %{id: 1, status: "paid"},
      timestamp: DateTime.utc_now(),
      metadata: %{
        url: endpoint_url(bypass.port),
        secret: "whsec_wk743dme4lua6scxvm4gaoj5"
      }
    }

    assert {:ok, %Result{} = result} =
             StandardWebhooksDispatcher.dispatch(params)

    assert result.status == :success
    assert result.error == nil
    assert result.metadata == %{}
    assert result.response.status == 200
    assert result.response.private[:latency_ms] >= 0
    assert result.response.body == Jason.encode!(res_data)

    headers = result.response.private[:headers]
    assert headers["webhook-id"] == ["lcjinejt23v6njnpmlmgz7sl"]

    assert headers["webhook-timestamp"] == [
             timestamp |> DateTime.to_unix() |> Integer.to_string()
           ]
  end

  test "dispatch/1 failed request", %{bypass: bypass} do
    res_data = %{status: "failed"}

    Bypass.expect_once(bypass, "POST", "/v1/webhooks", fn conn ->
      Plug.Conn.resp(conn, 400, Jason.encode!(res_data))
    end)

    timestamp = DateTime.utc_now()

    params = %Params{
      event_id: "lcjinejt23v6njnpmlmgz7sl",
      topic: "transaction.paid",
      data: %{id: 1, status: "paid"},
      timestamp: DateTime.utc_now(),
      metadata: %{
        url: endpoint_url(bypass.port),
        secret: "whsec_wk743dme4lua6scxvm4gaoj5"
      }
    }

    assert {:error, %Result{} = result} =
             StandardWebhooksDispatcher.dispatch(params)

    assert result.status == :failed
    assert result.error == "400"
    assert result.metadata == %{}
    assert result.response.status == 400
    assert result.response.private[:latency_ms] >= 0
    assert result.response.body == Jason.encode!(res_data)

    headers = result.response.private[:headers]
    assert headers["webhook-id"] == ["lcjinejt23v6njnpmlmgz7sl"]

    assert headers["webhook-timestamp"] == [
             timestamp |> DateTime.to_unix() |> Integer.to_string()
           ]
  end

  test "dispatch/1 transport error" do
    res_data = %{status: "failed"}

    timestamp = DateTime.utc_now()

    params = %Params{
      event_id: "lcjinejt23v6njnpmlmgz7sl",
      topic: "transaction.paid",
      data: %{id: 1, status: "paid"},
      timestamp: DateTime.utc_now(),
      metadata: %{
        url: endpoint_url("4678"),
        secret: "whsec_wk743dme4lua6scxvm4gaoj5"
      }
    }

    assert {:error, %Result{} = result} =
             StandardWebhooksDispatcher.dispatch(params)

    assert result.status == :failed
    assert result.error == "econnrefused"
    assert result.metadata == %{}
    assert result.response == nil
  end

  defp endpoint_url(port), do: "http://localhost:#{port}/v1/webhooks"
end
