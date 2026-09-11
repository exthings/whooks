defmodule WhooksWeb.UI.Admin.ProjectControllerTest do
  use WhooksWeb.ConnCase, async: false

  import Whooks.OrganizationsFixtures
  import Whooks.ProjectsFixtures
  import Whooks.ConsumersFixtures
  import Whooks.TopicsFixtures
  import Whooks.EventsFixtures
  import Whooks.AuthFixtures

  setup do
    org = organization_fixture()
    user = user_fixture(%{role: "admin"})
    project = project_fixture(%{organization_id: org.id})
    consumer = consumer_fixture(%{organization_id: org.id})
    topic = topic_fixture(%{project_id: project.id})

    %{
      org: org,
      user: user,
      project: project,
      consumer: consumer,
      topic: topic
    }
  end

  describe "recover_failed/2" do
    test "enqueues failed events for retry across project", %{
      conn: conn,
      org: org,
      user: user,
      project: project,
      consumer: consumer,
      topic: topic
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
        |> post(~p"/ui/admin/#{org.id}/projects/#{project.id}/recover-failed", %{})

      assert redirected_to(conn) == ~p"/ui/admin/#{org.id}/projects/#{project.id}"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Successfully enqueued"
    end
  end

  describe "bulk_replay/2" do
    test "enqueues matching events for bulk replay across project", %{
      conn: conn,
      org: org,
      user: user,
      project: project,
      consumer: consumer,
      topic: topic
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
        |> post(~p"/ui/admin/#{org.id}/projects/#{project.id}/bulk-replay", %{
          "topic_ids" => [to_string(topic.id)]
        })

      assert redirected_to(conn) == ~p"/ui/admin/#{org.id}/projects/#{project.id}"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Successfully enqueued"
    end
  end
end
