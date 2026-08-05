defmodule WhooksWeb.EndpointControllerTest do
  use WhooksWeb.ConnCase

  import Whooks.ConsumersFixtures
  import Whooks.EndpointsFixtures
  import Whooks.OrganizationsFixtures
  import Whooks.ProjectsFixtures
  import Whooks.TopicsFixtures
  alias Whooks.Endpoints.Endpoint

  setup %{conn: conn} do
    api_key = System.get_env("API_KEY") || "c700skca022vq2ljsoujy6lp"

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{api_key}")

    organization = organization_fixture()
    project = project_fixture(%{organization_id: organization.id})
    consumer = consumer_fixture()
    topic = topic_fixture(%{project_id: project.id})

    {:ok, conn: conn, project: project, consumer: consumer, topic: topic}
  end

  describe "index" do
    test "lists all endpoints", %{conn: conn} do
      conn = get(conn, ~p"/v1/endpoints")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create endpoint" do
    test "renders endpoint when data is valid", %{
      conn: conn,
      project: project,
      consumer: consumer,
      topic: topic
    } do
      create_attrs = %{
        consumer_id: consumer.id,
        project_id: project.id,
        status: "enabled",
        url: "http://localhost:4001",
        description: "Localhost endpoint",
        metadata: %{},
        headers: %{},
        subscribe: [topic.name]
      }

      conn = post(conn, ~p"/v1/endpoints", create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/v1/endpoints/#{id}")

      assert %{
               "id" => ^id,
               "description" => "Localhost endpoint",
               "headers" => %{},
               "metadata" => %{},
               "status" => "enabled",
               "url" => "http://localhost:4001"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{
      conn: conn,
      project: project,
      consumer: consumer,
      topic: topic
    } do
      invalid_attrs = %{
        consumer_id: consumer.id,
        project_id: project.id,
        status: nil,
        url: nil,
        description: nil,
        subscribe: [topic.name]
      }

      conn = post(conn, ~p"/v1/endpoints", invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "show endpoint" do
    setup [:create_endpoint]

    test "renders endpoint", %{conn: conn, endpoint: %Endpoint{id: endpoint_id}} do
      id = to_string(endpoint_id)
      conn = get(conn, ~p"/v1/endpoints/#{id}")

      assert %{
               "id" => ^id,
               "description" => "Localhost endpoint",
               "headers" => %{},
               "metadata" => %{},
               "status" => "enabled",
               "url" => "http://localhost:4001"
             } = json_response(conn, 200)["data"]
    end
  end

  defp create_endpoint(%{project: project, consumer: consumer}) do
    endpoint = endpoint_fixture(%{project_id: project.id, consumer_id: consumer.id})

    %{endpoint: endpoint}
  end
end
