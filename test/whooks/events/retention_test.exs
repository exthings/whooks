defmodule Whooks.Events.RetentionTest do
  use Whooks.DataCase, async: true

  alias Whooks.Repo
  alias Whooks.Events.Retention
  alias Whooks.Events.Event
  alias Whooks.DeliveryAttempts.DeliveryAttempt
  import Whooks.OrganizationsFixtures
  import Whooks.ProjectsFixtures
  import Whooks.ConsumersFixtures
  import Whooks.TopicsFixtures
  import Whooks.EndpointsFixtures
  import Whooks.SubscriptionsFixtures
  import Whooks.EventsFixtures

  setup do
    org1 = organization_fixture(%{name: "Org 30 Days", event_retention_days: 30})
    org2 = organization_fixture(%{name: "Org Indefinite", event_retention_days: nil})
    org3 = organization_fixture(%{name: "Org 7 Days", event_retention_days: 7})

    project1 = project_fixture(%{organization_id: org1.id})
    consumer1 = consumer_fixture(%{organization_id: org1.id})
    topic1 = topic_fixture(%{project_id: project1.id})
    endpoint1 = endpoint_fixture(%{consumer_id: consumer1.id, project_id: project1.id})
    [subscription1] = subscription_fixture(%{endpoint_id: endpoint1.id, topics: [topic1.id]})

    project2 = project_fixture(%{organization_id: org2.id})
    consumer2 = consumer_fixture(%{organization_id: org2.id})
    topic2 = topic_fixture(%{project_id: project2.id})

    %{
      org1: org1,
      org2: org2,
      org3: org3,
      project1: project1,
      consumer1: consumer1,
      topic1: topic1,
      endpoint1: endpoint1,
      subscription1: subscription1,
      project2: project2,
      consumer2: consumer2,
      topic2: topic2
    }
  end

  describe "list_organizations_with_retention/0" do
    test "returns only organizations with positive event_retention_days", %{
      org1: org1,
      org2: _org2,
      org3: org3
    } do
      orgs = Retention.list_organizations_with_retention()
      org_ids = Enum.map(orgs, & &1.id)

      assert org1.id in org_ids
      assert org3.id in org_ids
      refute Enum.any?(orgs, &is_nil(&1.event_retention_days))
    end
  end

  describe "purge_organization_events/3" do
    test "purges events older than retention_days and cascades delivery_attempts", %{
      org1: org1,
      project1: project1,
      consumer1: consumer1,
      topic1: topic1,
      subscription1: subscription1,
      project2: project2,
      consumer2: consumer2,
      topic2: topic2
    } do
      # 1. Event in org1 older than 30 days (e.g. 35 days ago)
      old_event =
        event_fixture(%{
          project_id: project1.id,
          consumer_id: consumer1.id,
          topic_id: topic1.id
        })

      old_time =
        DateTime.utc_now()
        |> DateTime.add(-35, :day)
        |> DateTime.truncate(:second)

      Repo.update_all(from(e in Event, where: e.id == ^old_event.id),
        set: [inserted_at: old_time]
      )

      # Add delivery_attempt to old_event
      attempt_attrs = %{
        id: DeliveryAttempt.gen_id(),
        status: :success,
        ip: "127.0.0.1",
        req_headers: %{},
        res_status: 200,
        latency_ms: 10,
        subscription_id: subscription1.id,
        event_id: old_event.id
      }

      {:ok, attempt} =
        %DeliveryAttempt{}
        |> DeliveryAttempt.create_changeset(attempt_attrs)
        |> Repo.insert()

      # 2. Event in org1 newer than 30 days (e.g. 10 days ago)
      recent_event =
        event_fixture(%{
          project_id: project1.id,
          consumer_id: consumer1.id,
          topic_id: topic1.id
        })

      recent_time =
        DateTime.utc_now()
        |> DateTime.add(-10, :day)
        |> DateTime.truncate(:second)

      Repo.update_all(from(e in Event, where: e.id == ^recent_event.id),
        set: [inserted_at: recent_time]
      )

      # 3. Old event in org2 (retention nil - should NOT be purged)
      org2_old_event =
        event_fixture(%{
          project_id: project2.id,
          consumer_id: consumer2.id,
          topic_id: topic2.id
        })

      Repo.update_all(from(e in Event, where: e.id == ^org2_old_event.id),
        set: [inserted_at: old_time]
      )

      # Execute purge for org1
      assert {:ok, 1} = Retention.purge_organization_events(org1.id, 30, 1000)

      # Verify old_event and its delivery_attempt were deleted
      assert Repo.get(Event, old_event.id) == nil
      assert Repo.get(DeliveryAttempt, attempt.id) == nil

      # Verify recent event and org2 event are untouched
      assert Repo.get(Event, recent_event.id) != nil
      assert Repo.get(Event, org2_old_event.id) != nil
    end

    test "respects batch_size limit and returns number of purged records", %{
      org1: org1,
      project1: project1,
      consumer1: consumer1,
      topic1: topic1
    } do
      old_time =
        DateTime.utc_now()
        |> DateTime.add(-40, :day)
        |> DateTime.truncate(:second)

      event_ids =
        for _ <- 1..5 do
          event =
            event_fixture(%{
              project_id: project1.id,
              consumer_id: consumer1.id,
              topic_id: topic1.id
            })

          Repo.update_all(from(e in Event, where: e.id == ^event.id),
            set: [inserted_at: old_time]
          )

          event.id
        end

      # Purge with batch_size 2
      assert {:ok, 2} = Retention.purge_organization_events(org1.id, 30, 2)

      # Check 3 remaining
      remaining_count = Repo.aggregate(from(e in Event, where: e.id in ^event_ids), :count)
      assert remaining_count == 3
    end
  end
end
