defmodule WhooksWeb.TopicControllerTest do
  use WhooksWeb.ConnCase

  import Whooks.OrganizationsFixtures
  import Whooks.ProjectsFixtures
  import Whooks.TopicsFixtures
  alias Whooks.Topics.Topic

  @invalid_attrs %{name: nil, status: nil, description: nil, json_schema: nil}

  setup %{conn: conn} do
    api_key = System.get_env("API_KEY") || "c700skca022vq2ljsoujy6lp"

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{api_key}")

    organization = organization_fixture()
    project = project_fixture(%{organization_id: organization.id})

    {:ok, conn: conn, project: project}
  end

  describe "index" do
    test "lists all topics", %{conn: conn} do
      conn = get(conn, ~p"/v1/topics")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create topic" do
    test "renders topic when data is valid", %{conn: conn, project: project} do
      create_attrs = %{
        name: "user.created",
        status: "enabled",
        description: "some description",
        json_schema: %{},
        project_id: project.id
      }

      conn = post(conn, ~p"/v1/topics", create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/v1/topics/#{id}")

      assert %{
               "id" => ^id,
               "description" => "some description",
               "json_schema" => %{},
               "name" => "user.created",
               "status" => "enabled"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/v1/topics", @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "show topic" do
    setup [:create_topic]

    test "renders topic", %{conn: conn, topic: %Topic{id: topic_id}} do
      id = to_string(topic_id)
      conn = get(conn, ~p"/v1/topics/#{id}")

      assert %{
               "id" => ^id,
               "description" => "Transaction approved event",
               "json_schema" => %{
                 "properties" => %{"id" => %{"type" => "string"}},
                 "type" => "object"
               },
               "name" => "transaction.approved",
               "status" => "enabled"
             } = json_response(conn, 200)["data"]
    end
  end

  defp create_topic(%{project: project}) do
    topic = topic_fixture(%{project_id: project.id})

    %{topic: topic}
  end
end
