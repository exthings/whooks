defmodule WhooksWeb.SubscriptionControllerTest do
  use WhooksWeb.ConnCase

  import Whooks.ConsumersFixtures
  import Whooks.EndpointsFixtures
  import Whooks.OrganizationsFixtures
  import Whooks.ProjectsFixtures
  import Whooks.SubscriptionsFixtures
  import Whooks.TopicsFixtures
  alias Whooks.Subscriptions.Subscription

  @invalid_attrs %{status: nil}

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
    endpoint = endpoint_fixture(%{project_id: project.id, consumer_id: consumer.id})

    {:ok, conn: conn, project: project, topic: topic, endpoint: endpoint}
  end

  describe "index" do
    test "lists all subscriptions", %{conn: conn} do
      conn = get(conn, ~p"/v1/subscriptions")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create subscription" do
    test "renders subscription when data is valid", %{
      conn: conn,
      topic: topic,
      endpoint: endpoint
    } do
      create_attrs = %{
        status: "enabled",
        topic_id: topic.id,
        endpoint_id: endpoint.id
      }

      conn = post(conn, ~p"/v1/subscriptions", subscription: create_attrs)
      assert [%{"id" => id}] = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/v1/subscriptions/#{id}")

      assert %{
               "id" => ^id,
               "status" => "enabled"
             } =
               json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/v1/subscriptions", subscription: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "show subscription" do
    setup [:create_subscription]

    test "renders subscription", %{conn: conn, subscription: %Subscription{id: subscription_id}} do
      id = to_string(subscription_id)
      conn = get(conn, ~p"/v1/subscriptions/#{id}")

      assert %{
               "id" => ^id,
               "status" => "enabled"
             } = json_response(conn, 200)["data"]
    end
  end

  defp create_subscription(%{topic: topic, endpoint: endpoint}) do
    [subscription] =
      subscription_fixture(%{topic_id: topic.id, endpoint_id: endpoint.id, status: "enabled"})

    %{subscription: subscription}
  end
end
