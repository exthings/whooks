defmodule WhooksWeb.ConsumerControllerTest do
  use WhooksWeb.ConnCase

  import Whooks.ConsumersFixtures
  alias Whooks.Consumers.Consumer

  @create_attrs %{
    name: "some name",
    metadata: %{},
    uid: "some uid"
  }
  @invalid_attrs %{name: nil, metadata: nil, uid: nil}

  setup %{conn: conn} do
    api_key = System.get_env("API_KEY") || "c700skca022vq2ljsoujy6lp"

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{api_key}")

    {:ok, conn: conn}
  end

  describe "index" do
    test "lists all consumers", %{conn: conn} do
      conn = get(conn, ~p"/v1/consumers")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create consumer" do
    test "renders consumer when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/v1/consumers", @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/v1/consumers/#{id}")

      assert %{
               "id" => ^id,
               "metadata" => %{},
               "name" => "some name",
               "uid" => "some uid"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/v1/consumers", @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "show consumer" do
    setup [:create_consumer]

    test "renders consumer", %{conn: conn, consumer: %Consumer{id: consumer_id}} do
      id = to_string(consumer_id)
      conn = get(conn, ~p"/v1/consumers/#{id}")

      assert %{
               "id" => ^id,
               "metadata" => %{},
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end
  end

  defp create_consumer(_) do
    consumer = consumer_fixture()

    %{consumer: consumer}
  end
end
