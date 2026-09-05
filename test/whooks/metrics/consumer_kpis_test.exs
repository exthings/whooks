defmodule Whooks.Metrics.ConsumerKpisTest do
  use Whooks.DataCase, async: true

  import Whooks.OrganizationsFixtures
  import Whooks.ProjectsFixtures
  import Whooks.ConsumersFixtures
  import Whooks.TopicsFixtures
  import Whooks.EndpointsFixtures
  import Whooks.EventsFixtures

  alias Whooks.Metrics

  describe "consumer_kpis/2" do
    test "returns zeros when consumer has no events or endpoints" do
      consumer = consumer_fixture()

      assert {:ok, kpis} = Metrics.consumer_kpis(consumer.id)

      assert kpis == %{
               total_events: 0,
               successful_events: 0,
               failed_events: 0,
               success_rate: 100.0,
               active_endpoints_count: 0
             }
    end

    test "calculates correct counts and success rate for a consumer" do
      org = organization_fixture()
      project = project_fixture(%{organization_id: org.id})
      consumer = consumer_fixture(%{organization_id: org.id})
      topic = topic_fixture(%{project_id: project.id})

      # Create endpoints
      _ep1 =
        endpoint_fixture(%{consumer_id: consumer.id, project_id: project.id, status: :enabled})

      _ep2 =
        endpoint_fixture(%{consumer_id: consumer.id, project_id: project.id, status: :enabled})

      # Create events
      _event1 =
        event_fixture(%{
          consumer_id: consumer.id,
          project_id: project.id,
          topic_id: topic.id,
          status: :success
        })

      _event2 =
        event_fixture(%{
          consumer_id: consumer.id,
          project_id: project.id,
          topic_id: topic.id,
          status: :success
        })

      _event3 =
        event_fixture(%{
          consumer_id: consumer.id,
          project_id: project.id,
          topic_id: topic.id,
          status: :failed
        })

      assert {:ok, kpis} = Metrics.consumer_kpis(consumer.id, last: "24h")

      assert kpis.total_events == 3
      assert kpis.successful_events == 2
      assert kpis.failed_events == 1
      assert Float.round(kpis.success_rate, 1) == 66.7
      assert kpis.active_endpoints_count == 2
    end
  end
end
