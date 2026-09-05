defmodule Whooks.RetentionMigrationsTest do
  use Whooks.DataCase, async: true

  alias Whooks.Repo
  alias Whooks.Events.Event
  alias Whooks.DeliveryAttempts.DeliveryAttempt
  import Whooks.OrganizationsFixtures
  import Whooks.ProjectsFixtures
  import Whooks.ConsumersFixtures
  import Whooks.TopicsFixtures
  import Whooks.EndpointsFixtures
  import Whooks.SubscriptionsFixtures
  import Whooks.EventsFixtures

  describe "database cascading" do
    test "deleting an event automatically cascades and deletes related delivery_attempts" do
      org = organization_fixture()
      project = project_fixture(%{organization_id: org.id})
      consumer = consumer_fixture(%{organization_id: org.id})
      topic = topic_fixture(%{project_id: project.id})
      endpoint = endpoint_fixture(%{consumer_id: consumer.id, project_id: project.id})
      [subscription] =
        subscription_fixture(%{endpoint_id: endpoint.id, topics: [topic.id]})

      event =
        event_fixture(%{
          project_id: project.id,
          consumer_id: consumer.id,
          topic_id: topic.id
        })

      attempt_attrs = %{
        id: DeliveryAttempt.gen_id(),
        status: :success,
        ip: "127.0.0.1",
        req_headers: %{"content-type" => "application/json"},
        res_status: 200,
        latency_ms: 50,
        subscription_id: subscription.id,
        event_id: event.id
      }

      {:ok, %DeliveryAttempt{} = attempt} =
        %DeliveryAttempt{}
        |> DeliveryAttempt.create_changeset(attempt_attrs)
        |> Repo.insert()

      assert Repo.get(DeliveryAttempt, attempt.id) != nil

      # Delete event
      {1, _} = Repo.delete_all(from(e in Event, where: e.id == ^event.id))

      # Assert delivery_attempt was deleted by database CASCADE
      assert Repo.get(DeliveryAttempt, attempt.id) == nil
    end
  end
end
