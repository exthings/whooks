defmodule Whooks.DeliveryAttemptsTest do
  use Whooks.DataCase

  alias Whooks.DeliveryAttempts
  alias Whooks.DeliveryAttempts.DeliveryAttempt

  import Whooks.OrganizationsFixtures
  import Whooks.ConsumersFixtures
  import Whooks.TopicsFixtures
  import Whooks.EndpointsFixtures
  import Whooks.ProjectsFixtures
  import Whooks.SubscriptionsFixtures
  import Whooks.EventsFixtures
  import Whooks.DeliveryAttemptsFixtures

  setup do
    org = organization_fixture()
    consumer = consumer_fixture(%{organization_id: org.id})
    project = project_fixture(%{organization_id: org.id})
    topic = topic_fixture(%{project_id: project.id})

    endpoint =
      endpoint_fixture(%{
        consumer_id: consumer.id,
        project_id: project.id,
        url: "http://localhost:4001/v1/webhooks",
        secret: "signsecret"
      })

    [subscription] =
      subscription_fixture(%{endpoint_id: endpoint.id, topics: [topic.id]})

    %{
      org: org,
      subscription: subscription,
      project: project,
      consumer: consumer,
      topic: topic
    }
  end

  describe "delivery_attempts" do
    @invalid_attrs %{
      status: nil,
      req_headers: nil,
      res_headers: nil,
      res_status: nil,
      latency_ms: nil
    }

    setup data do
      event =
        event_fixture(%{
          project_id: data.project.id,
          topic_id: data.topic.id,
          consumer_id: data.consumer.id
        })

      %{event: event}
    end

    test "create_success/1 with valid data", data do
      valid_attrs = %{
        status: :success,
        req_headers: %{sample: "data"},
        res_headers: %{sample: "response"},
        res_status: 200,
        res_body: %{sample: "response"},
        latency_ms: 50,
        subscription_id: data.subscription.id,
        event_id: data.event.id
      }

      assert {:ok, %DeliveryAttempt{} = delivery_attempt} =
               DeliveryAttempts.create_success(valid_attrs)

      assert delivery_attempt.status == :success
      assert delivery_attempt.req_headers == %{sample: "data"}
      assert delivery_attempt.res_headers == %{sample: "response"}
      assert delivery_attempt.res_status == 200
      assert delivery_attempt.res_body == %{sample: "response"}
      assert delivery_attempt.latency_ms == 50
    end

    test "create_failed/1 with valid data", data do
      valid_attrs = %{
        status: :success,
        req_headers: %{sample: "data"},
        res_headers: %{sample: "response"},
        res_status: 400,
        res_body: %{sample: "response"},
        latency_ms: 50,
        subscription_id: data.subscription.id,
        event_id: data.event.id
      }

      assert {:ok, %DeliveryAttempt{} = delivery_attempt} =
               DeliveryAttempts.create_failed(valid_attrs)

      assert delivery_attempt.status == :failed
      assert delivery_attempt.req_headers == %{sample: "data"}
      assert delivery_attempt.res_headers == %{sample: "response"}
      assert delivery_attempt.res_status == 400
      assert delivery_attempt.res_body == %{sample: "response"}
      assert delivery_attempt.latency_ms == 50
    end
  end
end
