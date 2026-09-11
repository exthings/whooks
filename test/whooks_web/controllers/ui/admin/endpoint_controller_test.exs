defmodule WhooksWeb.UI.Admin.EndpointControllerTest do
  use WhooksWeb.ConnCase, async: false

  import Whooks.OrganizationsFixtures
  import Whooks.ProjectsFixtures
  import Whooks.ConsumersFixtures
  import Whooks.EndpointsFixtures
  import Whooks.TopicsFixtures
  import Whooks.SubscriptionsFixtures
  import Whooks.EventsFixtures
  import Whooks.AuthFixtures

  setup do
    org = organization_fixture()
    user = user_fixture(%{role: "admin"})
    project = project_fixture(%{organization_id: org.id})
    consumer = consumer_fixture(%{organization_id: org.id})
    topic = topic_fixture(%{project_id: project.id})

    endpoint =
      endpoint_fixture(%{
        consumer_id: consumer.id,
        project_id: project.id,
        url: "http://localhost:4000/webhook"
      })

    _sub = subscription_fixture(%{endpoint_id: endpoint.id, topics: [topic.id]})

    %{
      org: org,
      user: user,
      project: project,
      consumer: consumer,
      topic: topic,
      endpoint: endpoint
    }
  end

  describe "recover_failed/2" do
    test "enqueues failed events for retry", %{
      conn: conn,
      org: org,
      user: user,
      project: project,
      consumer: consumer,
      topic: topic,
      endpoint: endpoint
    } do
      _failed_event =
        event_fixture(%{
          project_id: project.id,
          consumer_id: consumer.id,
          topic_id: topic.id,
          status: :failed
        })

      conn =
        conn
        |> log_in_user(user)
        |> post(~p"/ui/admin/#{org.id}/endpoints/#{endpoint.id}/recover-failed", %{})

      assert redirected_to(conn) == ~p"/ui/admin/#{org.id}/endpoints/#{endpoint.id}"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Successfully enqueued"
    end
  end

  describe "replay_missing/2" do
    test "enqueues missing events for replay", %{
      conn: conn,
      org: org,
      user: user,
      endpoint: endpoint
    } do
      conn =
        conn
        |> log_in_user(user)
        |> post(~p"/ui/admin/#{org.id}/endpoints/#{endpoint.id}/replay-missing", %{})

      assert redirected_to(conn) == ~p"/ui/admin/#{org.id}/endpoints/#{endpoint.id}"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Successfully enqueued"
    end
  end

  describe "bulk_replay/2" do
    test "enqueues matching events for bulk replay", %{
      conn: conn,
      org: org,
      user: user,
      project: project,
      consumer: consumer,
      topic: topic,
      endpoint: endpoint
    } do
      _event =
        event_fixture(%{
          project_id: project.id,
          consumer_id: consumer.id,
          topic_id: topic.id,
          status: :success
        })

      conn =
        conn
        |> log_in_user(user)
        |> post(~p"/ui/admin/#{org.id}/endpoints/#{endpoint.id}/bulk-replay", %{
          "topic_ids" => [to_string(topic.id)]
        })

      assert redirected_to(conn) == ~p"/ui/admin/#{org.id}/endpoints/#{endpoint.id}"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Successfully enqueued"
    end
  end
end
