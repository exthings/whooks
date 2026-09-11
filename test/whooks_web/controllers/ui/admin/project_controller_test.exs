defmodule WhooksWeb.UI.Admin.ProjectControllerTest do
  use WhooksWeb.ConnCase, async: false

  import Whooks.OrganizationsFixtures
  import Whooks.ProjectsFixtures
  import Whooks.ConsumersFixtures
  import Whooks.TopicsFixtures
  import Whooks.EndpointsFixtures
  import Whooks.SubscriptionsFixtures
  import Whooks.EventsFixtures
  import Whooks.AuthFixtures

  alias Whooks.Repo

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
      endpoint =
        endpoint_fixture(%{
          consumer_id: consumer.id,
          project_id: project.id,
          url: "http://localhost:4000/webhook"
        })

      [sub] = subscription_fixture(%{endpoint_id: endpoint.id, topics: [topic.id]})

      event =
        event_fixture(%{
          project_id: project.id,
          consumer_id: consumer.id,
          topic_id: topic.id,
          status: :processed
        })

      {:ok, _attempt} =
        %Whooks.DeliveryAttempts.DeliveryAttempt{}
        |> Whooks.DeliveryAttempts.DeliveryAttempt.create_changeset(%{
          id: Whooks.DeliveryAttempts.DeliveryAttempt.gen_id() |> TypeID.to_string(),
          event_id: event.id,
          subscription_id: sub.id,
          status: :failed
        })
        |> Repo.insert()

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
          status: :processed
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
