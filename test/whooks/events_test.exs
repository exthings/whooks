defmodule Whooks.EventsTest do
  use Whooks.DataCase
  use ExUnit.Case, async: false

  alias Whooks.Events
  import Whooks.OrganizationsFixtures
  import Whooks.ConsumersFixtures
  import Whooks.TopicsFixtures
  import Whooks.EndpointsFixtures
  import Whooks.ProjectsFixtures
  import Whooks.SubscriptionsFixtures
  import Whooks.EventsFixtures

  require Logger

  setup_all do
    {:ok, queue_events} =
      BullMQ.QueueEvents.start_link(queue: "events", connection: :bullmq_redis)

    {:ok, queue_deliveries} =
      BullMQ.QueueEvents.start_link(queue: "deliveries", connection: :bullmq_redis)

    bypass = Bypass.open()

    on_exit(fn ->
      nil
      # Whooks.RedisCache.delete_all()
    end)

    %{queue_events: queue_events, queue_deliveries: queue_deliveries, bypass: bypass}
  end

  describe "events" do
    setup %{bypass: bypass} do
      org = organization_fixture()
      consumer = consumer_fixture(%{organization_id: org.id})
      project = project_fixture(%{organization_id: org.id})
      topic = topic_fixture(%{project_id: project.id})

      endpoint =
        endpoint_fixture(%{
          consumer_id: consumer.id,
          project_id: project.id,
          url: endpoint_url(bypass.port),
          secret: "signsecret"
        })

      subscription =
        subscription_fixture(%{endpoint_id: endpoint.id, topics: [topic.id]})

      %{
        org: org,
        consumer: consumer,
        topic: topic,
        endpoint: endpoint,
        project: project,
        subscription: subscription
      }
    end

    test "list/2", data do
      _event =
        event_fixture(%{
          project_id: data.project.id,
          topic_id: data.topic.id,
          consumer_id: data.consumer.id
        })

      assert {:ok, {[_fetched_event], %Flop.Meta{} = _metadata}} = Events.list(%{})
    end

    test "get!/1 with event id and uid", data do
      event =
        event_fixture(%{
          project_id: data.project.id,
          topic_id: data.topic.id,
          consumer_id: data.consumer.id
        })

      assert %Events.Event{id: id} = Events.get!(to_string(event.id))
      assert id == event.id

      assert %Events.Event{id: id} = Events.get!(event.uid)
      assert id == event.id
    end

    test "update_to_scheduled/1", data do
      event =
        event_fixture(%{
          project_id: data.project.id,
          topic_id: data.topic.id,
          consumer_id: data.consumer.id
        })

      assert {:ok, updated_event} = Events.update_to_scheduled(event)
      assert updated_event.status == :scheduled
    end

    test "update_to_processing/1", data do
      event =
        event_fixture(%{
          project_id: data.project.id,
          topic_id: data.topic.id,
          consumer_id: data.consumer.id
        })

      assert {:ok, updated_event} = Events.update_to_processing(event)
      assert updated_event.status == :processing
    end

    test "update_to_success/1", data do
      event =
        event_fixture(%{
          project_id: data.project.id,
          topic_id: data.topic.id,
          consumer_id: data.consumer.id
        })

      assert {:ok, updated_event} = Events.update_to_success(event)
      assert updated_event.status == :success
    end

    test "update_to_retry/1", data do
      event =
        event_fixture(%{
          project_id: data.project.id,
          topic_id: data.topic.id,
          consumer_id: data.consumer.id
        })

      assert {:ok, updated_event} = Events.update_to_retry(event)
      assert updated_event.status == :retry
    end

    test "update_to_failed/1", data do
      event =
        event_fixture(%{
          project_id: data.project.id,
          topic_id: data.topic.id,
          consumer_id: data.consumer.id
        })

      assert {:ok, updated_event} = Events.update_to_failed(event)
      assert updated_event.status == :failed
    end

    test "update_to_partial_success/1", data do
      event =
        event_fixture(%{
          project_id: data.project.id,
          topic_id: data.topic.id,
          consumer_id: data.consumer.id
        })

      assert {:ok, updated_event} = Events.update_to_partial_success(event)
      assert updated_event.status == :partial_success
    end
  end

  describe "events success dispatching" do
    setup %{queue_events: queue_events, queue_deliveries: queue_deliveries, bypass: bypass} do
      BullMQ.QueueEvents.subscribe(queue_events, self())
      BullMQ.QueueEvents.subscribe(queue_deliveries, self())

      org = organization_fixture()
      consumer = consumer_fixture(%{organization_id: org.id})
      project = project_fixture(%{organization_id: org.id})
      topic = topic_fixture(%{project_id: project.id, validate_schema: true})

      endpoint =
        endpoint_fixture(%{
          consumer_id: consumer.id,
          project_id: project.id,
          url: endpoint_url(bypass.port),
          secret: "signsecret"
        })

      [subscription] =
        subscription_fixture(%{endpoint_id: endpoint.id, topics: [topic.id]})

      %{
        org: org,
        consumer: consumer,
        topic: topic,
        endpoint: endpoint,
        project: project,
        subscription: subscription,
        bypass: bypass
      }
    end

    test "create_event/1 is published to bullmq and dispatched", data do
      Bypass.expect(data.bypass, "POST", "/v1/webhooks", fn conn ->
        Plug.Conn.resp(conn, 200, Jason.encode!(%{status: "success"}))
      end)

      valid_attrs = %{
        "uid" => "uid-#{System.unique_integer([:positive])}",
        "consumer_id" => data.consumer.id |> TypeID.to_string(),
        "project_id" => data.project.id |> TypeID.to_string(),
        "topic" => data.topic.id |> TypeID.to_string(),
        "data" => %{
          "id" => "019bb3b7-57f7-7b28-9ad1-ce122c7a66c0"
        },
        "metadata" => %{
          "transaction_id" => "01KESVHY8HACK7HGVYPRP90WS0"
        },
        "tags" => [
          "tag-1"
        ]
      }

      assert {:ok, %{id: event_id, job_id: job_id}} = Events.enqueue(valid_attrs)
      assert_receive {:bullmq_event, :completed, %{"jobId" => ^job_id}}, 2000

      event_return = Jason.encode!(%{id: event_id})

      assert_receive {:bullmq_event, :completed, %{"returnvalue" => ^event_return}}, 2000

      assert_receive {:bullmq_event, :completed, %{"returnvalue" => returnvalue}}, 2000
      assert %{"status" => "success", "id" => "attempt_" <> _} = Jason.decode!(returnvalue)

      assert {:ok, event} = Events.get(event_id)
      assert event.status == :success
    end

    test "create_event/1 is published to bullmq and data validation fails", data do
      valid_attrs = %{
        "uid" => "uid-#{System.unique_integer([:positive])}",
        "consumer_id" => data.consumer.id |> TypeID.to_string(),
        "project_id" => data.project.id |> TypeID.to_string(),
        "topic" => data.topic.id |> TypeID.to_string(),
        "data" => %{
          "uid" => "019bb3b7-57f7-7b28-9ad1-ce122c7a66c0"
        },
        "metadata" => %{
          "transaction_id" => "01KESVHY8HACK7HGVYPRP90WS0"
        },
        "tags" => [
          "tag-1"
        ]
      }

      assert {:ok, %{id: event_id, job_id: job_id}} = Events.enqueue(valid_attrs)
      assert_receive {:bullmq_event, :completed, %{"jobId" => ^job_id}}, 2000

      assert {:ok, event} = Events.get(event_id)
      assert event.status == :failed
      assert event.metadata["failed_reason"] == "Required properties are missing: [\"id\"]."
    end

    test "create_event/1 verifies idempotency", data do
      Bypass.expect(data.bypass, "POST", "/v1/webhooks", fn conn ->
        Plug.Conn.resp(conn, 200, Jason.encode!(%{status: "success"}))
      end)

      valid_attrs = %{
        "uid" => "uid-#{System.unique_integer([:positive])}",
        "consumer_id" => data.consumer.id,
        "project_id" => data.project.id,
        "topic" => data.topic.id,
        "data" => %{
          "id" => "019bb3b7-57f7-7b28-9ad1-ce122c7a66c0",
          "status" => "completed",
          "amount" => "15"
        },
        "metadata" => %{
          "transaction_id" => "01KESVHY8HACK7HGVYPRP90WS0"
        },
        "tags" => [
          "tag-2"
        ]
      }

      assert {:ok, %{id: _event_id, job_id: job_id}} = Events.enqueue(valid_attrs)
      assert_receive {:bullmq_event, :completed, %{"jobId" => ^job_id}}, 2000
      assert_receive {:bullmq_event, :completed, %{"returnvalue" => delivery_return}}, 2000

      delivery_return = Jason.decode!(delivery_return)
      assert String.starts_with?(delivery_return["id"], "attempt_")
      assert delivery_return["status"] == "success"

      assert {:ok, %Whooks.Events.Event{}} = Events.enqueue(valid_attrs)
    end
  end

  describe "events failing to dispatch" do
    setup %{queue_events: queue_events, queue_deliveries: queue_deliveries, bypass: bypass} do
      BullMQ.QueueEvents.subscribe(queue_events, self())
      BullMQ.QueueEvents.subscribe(queue_deliveries, self())

      org = organization_fixture()
      consumer = consumer_fixture(%{organization_id: org.id})
      project = project_fixture(%{organization_id: org.id})
      topic = topic_fixture(%{project_id: project.id})

      res_data = %{status: "success"}

      Bypass.expect(bypass, "POST", "/v1/webhooks", fn conn ->
        Plug.Conn.resp(conn, 400, Jason.encode!(res_data))
      end)

      endpoint =
        endpoint_fixture(%{
          consumer_id: consumer.id,
          project_id: project.id,
          url: endpoint_url(bypass.port),
          secret: "signsecret"
        })

      Logger.info("Endpoint #{inspect(endpoint)}")

      [subscription] =
        subscription_fixture(%{endpoint_id: endpoint.id, topics: [topic.id]})

      %{
        org: org,
        consumer: consumer,
        topic: topic,
        endpoint: endpoint,
        project: project,
        subscription: subscription
      }
    end

    test "create_event/1 is published to bullmq and fail to dispatch", data do
      valid_attrs = %{
        "uid" => "uid-#{System.unique_integer([:positive])}",
        "consumer_id" => data.consumer.id |> TypeID.to_string(),
        "project_id" => data.project.id |> TypeID.to_string(),
        "topic" => data.topic.id |> TypeID.to_string(),
        "data" => %{
          "id" => "019bb3b7-57f7-7b28-9ad1-ce122c7a66c0",
          "status" => "completed",
          "amount" => "15"
        },
        "metadata" => %{
          "transaction_id" => "01KESVHY8HACK7HGVYPRP90WS0"
        },
        "tags" => [
          "tag-1"
        ]
      }

      assert {:ok, %{id: event_id, job_id: job_id}} = Events.enqueue(valid_attrs)
      assert_receive {:bullmq_event, :completed, %{"jobId" => ^job_id}}, 2000
      assert_receive {:bullmq_event, :delayed, %{}}, 2000
      assert_receive {:bullmq_event, :failed, %{}}, 50000

      assert_receive {:bullmq_event, :completed, %{"returnvalue" => delivery_return}},
                     50000

      delivery_return = Jason.decode!(delivery_return)
      assert delivery_return["id"] == event_id
    end
  end

  describe "event creation resilience" do
    setup do
      org = organization_fixture()
      consumer = consumer_fixture(%{organization_id: org.id})
      project = project_fixture(%{organization_id: org.id})
      topic = topic_fixture(%{project_id: project.id})

      %{
        org: org,
        consumer: consumer,
        project: project,
        topic: topic
      }
    end

    test "updates event status to no_subscribers", %{
      project: project,
      topic: topic,
      consumer: consumer
    } do
      {:ok, event} =
        Events.create(%{
          uid: "test-no-subs-#{System.unique_integer()}",
          data: %{"hello" => "world"},
          project_id: project.id,
          topic_id: topic.id,
          consumer_id: consumer.id
        })

      assert {:ok, updated_event} = Events.update_to_no_subscribers(event)
      assert updated_event.status == :no_subscribers
    end

    test "enqueue uses uid for deduplication when present", %{
      project: project,
      topic: topic,
      consumer: consumer
    } do
      uid = "unique-uid-#{System.unique_integer()}"

      attrs = %{
        "uid" => uid,
        "topic" => topic.name,
        "project_id" => TypeID.to_string(project.id),
        "consumer_id" => TypeID.to_string(consumer.id),
        "data" => %{"key" => "value"}
      }

      assert {:ok, %{id: event_id, job_id: job_id}} = Events.enqueue(attrs)
      assert is_binary(event_id)
      assert is_binary(job_id)
    end

    test "enqueue falls back to generated id when uid is nil or empty", %{
      project: project,
      topic: topic,
      consumer: consumer
    } do
      attrs = %{
        "topic" => topic.name,
        "project_id" => TypeID.to_string(project.id),
        "consumer_id" => TypeID.to_string(consumer.id),
        "data" => %{"key" => "value"}
      }

      assert {:ok, %{id: event_id, job_id: job_id}} = Events.enqueue(attrs)
      assert String.starts_with?(event_id, "event_")
      assert is_binary(job_id)
    end

    test "create is idempotent when event already exists", %{
      project: project,
      topic: topic,
      consumer: consumer
    } do
      attrs = %{
        "uid" => "idempotent-uid-#{System.unique_integer()}",
        "topic_id" => topic.id,
        "project_id" => project.id,
        "consumer_id" => consumer.id,
        "data" => %{"key" => "val"}
      }

      assert {:ok, event1} = Events.create(attrs)
      assert {:ok, event2} = Events.create(attrs)
      assert event1.id == event2.id
    end

    test "create job with zero subscriptions marks event as no_subscribers", %{
      project: project,
      consumer: consumer
    } do
      topic_without_subs =
        topic_fixture(%{
          project_id: project.id,
          name: "topic.nosubscriptions"
        })

      attrs = %{
        "uid" => "idempotent-uid-#{System.unique_integer()}",
        "topic" => topic_without_subs.name,
        "project_id" => TypeID.to_string(project.id),
        "consumer_id" => TypeID.to_string(consumer.id),
        "data" => %{"message" => "no subscribers here"}
      }

      job = %BullMQ.Job{id: "job_test_1", queue_name: "events", name: "create", data: attrs}

      assert {:ok, %{event_id: event_id, status: :no_subscribers}} =
               WhooksWorker.EventsWorker.process(job)

      event = Events.get!(event_id)
      assert event.status == :no_subscribers
    end
  end

  defp endpoint_url(port), do: "http://localhost:#{port}/v1/webhooks"
end
