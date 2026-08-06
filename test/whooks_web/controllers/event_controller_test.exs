defmodule WhooksWeb.EventControllerTest do
  use WhooksWeb.ConnCase

  import Whooks.ConsumersFixtures
  import Whooks.EventsFixtures
  import Whooks.OrganizationsFixtures
  import Whooks.ProjectsFixtures
  import Whooks.TopicsFixtures
  alias Whooks.Events.Event

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
    test "lists all events", %{conn: conn} do
      conn = get(conn, ~p"/v1/events")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create event" do
    test "renders event when data is valid", %{
      conn: conn,
      project: project,
      consumer: consumer,
      topic: topic
    } do
      create_attrs = %{
        "uid" => "some-uid-#{System.unique_integer([:positive])}",
        "data" => %{"key" => "value"},
        "consumer_id" => consumer.id,
        "project_id" => project.id,
        "topic_id" => topic.id,
        "tags" => ["tag1"],
        "metadata" => %{}
      }

      conn = post(conn, ~p"/v1/events", create_attrs)
      assert %{"id" => _id} = json_response(conn, 201)["data"]
    end
  end

  describe "show event" do
    setup [:create_event]

    test "renders event", %{conn: conn, event: %Event{id: event_id}} do
      id = to_string(event_id)
      conn = get(conn, ~p"/v1/events/#{id}")

      assert %{
               "id" => ^id,
               "data" => %{"name" => "event1"},
               "tags" => ["tag1", "tag2"]
             } = json_response(conn, 200)["data"]
    end
  end

  defp create_event(%{project: project, consumer: consumer, topic: topic}) do
    event = event_fixture(%{project_id: project.id, consumer_id: consumer.id, topic_id: topic.id})

    %{event: event}
  end
end
