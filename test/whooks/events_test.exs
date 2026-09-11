defmodule Whooks.EventsTest do
  use Whooks.DataCase
  use ExUnit.Case, async: false

  alias Whooks.Events
  alias Whooks.Events.Event
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

    test "update_to_pending/1", data do
      event =
        event_fixture(%{
          project_id: data.project.id,
          topic_id: data.topic.id,
          consumer_id: data.consumer.id
        })

      assert {:ok, updated_event} = Events.update_to_pending(event)
      assert updated_event.status == :pending
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

    test "update_to_processed/1", data do
      event =
        event_fixture(%{
          project_id: data.project.id,
          topic_id: data.topic.id,
          consumer_id: data.consumer.id
        })

      assert {:ok, updated_event} = Events.update_to_processed(event)
      assert updated_event.status == :processed
    end

    test "update_to_unprocessed/1", data do
      event =
        event_fixture(%{
          project_id: data.project.id,
          topic_id: data.topic.id,
          consumer_id: data.consumer.id
        })

      assert {:ok, updated_event} = Events.update_to_unprocessed(event)
      assert updated_event.status == :unprocessed
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

      assert_receive {:bullmq_event, :completed, %{"returnvalue" => returnvalue}}, 2000
      assert %{"status" => "success", "id" => "attempt_" <> _} = Jason.decode!(returnvalue)

      assert {:ok, event} = Events.get(event_id)
      assert event.status == :processed
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
      assert event.status == :unprocessed
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
      assert_receive {:bullmq_event, :completed, %{"returnvalue" => ret1}}, 2000

      attempt_return = Jason.decode!(ret1)
      assert String.starts_with?(attempt_return["id"] || "", "attempt_")
      assert attempt_return["status"] == "success"

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

      event = Events.get!(event_id)
      assert event.status in [:processing, :processed]
    end
  end

  describe "event creation resilience" do
    setup %{queue_events: queue_events} do
      org = organization_fixture()
      consumer = consumer_fixture(%{organization_id: org.id})
      project = project_fixture(%{organization_id: org.id})
      topic = topic_fixture(%{project_id: project.id})

      %{
        org: org,
        consumer: consumer,
        project: project,
        topic: topic,
        queue_events: queue_events
      }
    end

    test "updates event status to unprocessed", %{
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

      assert {:ok, updated_event} = Events.update_to_unprocessed(event)
      assert updated_event.status == :unprocessed
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

      assert {:ok, %{event_id: event_id, status: :unprocessed}} =
               WhooksWorker.EventsWorker.process(job)

      event = Events.get!(event_id)
      assert event.status == :unprocessed
    end

    test "resend_batch enqueues jobs in bulk and handles empty or chunked input", %{
      project: project,
      topic: topic,
      consumer: consumer,
      queue_events: queue_events
    } do
      BullMQ.QueueEvents.subscribe(queue_events, self())

      assert {:ok, %{total_enqueued: 0}} = Events.resend_batch([])

      {:ok, event1} =
        Events.create(%{
          uid: "batch-1-#{System.unique_integer()}",
          topic_id: topic.id,
          project_id: project.id,
          consumer_id: consumer.id,
          data: %{"val" => 1}
        })

      {:ok, event2} =
        Events.create(%{
          uid: "batch-2-#{System.unique_integer()}",
          topic_id: topic.id,
          project_id: project.id,
          consumer_id: consumer.id,
          data: %{"val" => 2}
        })

      {:ok, event3} =
        Events.create(%{
          uid: "batch-3-#{System.unique_integer()}",
          topic_id: topic.id,
          project_id: project.id,
          consumer_id: consumer.id,
          data: %{"val" => 3}
        })

      # Test passing mix of %Event{} and string IDs, with batch_size: 2
      assert {:ok, %{total_enqueued: 3, job_ids: job_ids}} =
               Events.resend_batch([event1, event2.id, to_string(event3.id)], batch_size: 2)

      # Await the exact background jobs
      for job_id <- job_ids do
        assert_receive {:bullmq_event, :completed, %{"jobId" => ^job_id}}, 5000
      end

      # Verify events were processed and transitioned to unprocessed (topic has no subs)
      assert Events.get!(event1.id).status == :unprocessed
      assert Events.get!(event2.id).status == :unprocessed
      assert Events.get!(event3.id).status == :unprocessed
    end

    test "retry_failed queries failed events and enqueues them", %{
      project: project,
      topic: topic,
      consumer: consumer,
      queue_events: queue_events
    } do
      BullMQ.QueueEvents.subscribe(queue_events, self())

      {:ok, failed_event} =
        Events.create(%{
          uid: "failed-#{System.unique_integer()}",
          topic_id: topic.id,
          project_id: project.id,
          consumer_id: consumer.id,
          data: %{"val" => "failed"},
          status: :pending
        })

      endpoint = endpoint_fixture(%{consumer_id: consumer.id, project_id: project.id})
      [sub] = subscription_fixture(%{endpoint_id: endpoint.id, topics: [topic.id]})

      {:ok, _attempt} =
        %Whooks.DeliveryAttempts.DeliveryAttempt{}
        |> Whooks.DeliveryAttempts.DeliveryAttempt.create_changeset(%{
          id: Whooks.DeliveryAttempts.DeliveryAttempt.gen_id() |> TypeID.to_string(),
          event_id: failed_event.id,
          subscription_id: sub.id,
          status: :failed
        })
        |> Repo.insert()

      {:ok, success_event} =
        Events.create(%{
          uid: "success-#{System.unique_integer()}",
          topic_id: topic.id,
          project_id: project.id,
          consumer_id: consumer.id,
          data: %{"val" => "success"},
          status: :processed
        })

      assert {:ok, %{total_enqueued: 1, job_ids: job_ids}} =
               Events.retry_failed(
                 project_id: project.id,
                 consumer_id: consumer.id,
                 topic_id: topic.id
               )

      # Await the exact background jobs
      for job_id <- job_ids do
        assert_receive {:bullmq_event, :completed, %{"jobId" => ^job_id}}, 5000
      end

      # Failed event was retried and moved to processing or processed
      assert Events.get!(failed_event.id).status in [:processing, :processed]
      assert Events.get!(success_event.id).status == :processed
    end

    test "retry_missing queries past events created before endpoint subscriptions", %{
      org: org,
      bypass: bypass,
      queue_events: queue_events
    } do
      BullMQ.QueueEvents.subscribe(queue_events, self())

      Bypass.stub(bypass, "POST", "/v1/webhooks", fn conn ->
        Plug.Conn.resp(conn, 200, Jason.encode!(%{status: "success"}))
      end)

      # Create a new project, consumer, topic and endpoint
      new_project = project_fixture(%{organization_id: org.id})
      new_consumer = consumer_fixture(%{organization_id: org.id})
      new_topic = topic_fixture(%{project_id: new_project.id})

      new_endpoint =
        endpoint_fixture(%{
          consumer_id: new_consumer.id,
          project_id: new_project.id,
          url: endpoint_url(bypass.port),
          secret: "signsecret2"
        })

      # Create past events with inserted_at before subscription
      past_time = DateTime.utc_now() |> DateTime.add(-300, :second)

      {:ok, past_no_sub} =
        Events.create(%{
          uid: "past-no-sub-#{System.unique_integer()}",
          topic_id: new_topic.id,
          project_id: new_project.id,
          consumer_id: new_consumer.id,
          data: %{"test" => "no_sub"},
          status: :unprocessed
        })

      {:ok, past_success} =
        Events.create(%{
          uid: "past-success-#{System.unique_integer()}",
          topic_id: new_topic.id,
          project_id: new_project.id,
          consumer_id: new_consumer.id,
          data: %{"test" => "success"},
          status: :processed
        })

      {:ok, past_pending} =
        Events.create(%{
          uid: "past-pending-#{System.unique_integer()}",
          topic_id: new_topic.id,
          project_id: new_project.id,
          consumer_id: new_consumer.id,
          data: %{"test" => "pending"},
          status: :pending
        })

      {:ok, past_failed} =
        Events.create(%{
          uid: "past-failed-#{System.unique_integer()}",
          topic_id: new_topic.id,
          project_id: new_project.id,
          consumer_id: new_consumer.id,
          data: %{"test" => "failed"},
          status: :scheduled
        })

      Ecto.Query.from(e in Whooks.Events.Event,
        where: e.id in ^[past_no_sub.id, past_success.id, past_pending.id]
      )
      |> Repo.update_all(set: [inserted_at: past_time])

      # Now create subscription
      _subscription =
        subscription_fixture(%{endpoint_id: new_endpoint.id, topics: [new_topic.id]})

      # Create an event created after subscription
      {:ok, newer_event} =
        Events.create(%{
          uid: "newer-#{System.unique_integer()}",
          topic_id: new_topic.id,
          project_id: new_project.id,
          consumer_id: new_consumer.id,
          data: %{"test" => "newer"},
          status: :unprocessed
        })

      # retry_missing by endpoint struct
      assert {:ok, %{total_enqueued: 3, job_ids: job_ids}} = Events.retry_missing(new_endpoint)

      # Await the exact background jobs
      for job_id <- job_ids do
        assert_receive {:bullmq_event, :completed, %{"jobId" => ^job_id}}, 5000
      end

      # Target events were resent and transitioned to processing or processed
      assert Events.get!(past_no_sub.id).status in [:processing, :processed]
      assert Events.get!(past_success.id).status in [:processing, :processed]
      assert Events.get!(past_pending.id).status in [:processing, :processed]

      # Events that were not eligible retained their original status
      assert Events.get!(past_failed.id).status == :scheduled
      assert Events.get!(newer_event.id).status == :unprocessed
    end

    test "bulk_replay/1 resends events matching topic_ids and inserted_after", data do
      BullMQ.QueueEvents.subscribe(data.queue_events, self())

      Bypass.stub(data.bypass, "POST", "/v1/webhooks", fn conn ->
        Plug.Conn.resp(conn, 200, Jason.encode!(%{status: "success"}))
      end)

      {:ok, event1} =
        Events.create(%{
          uid: "bulk-1-#{System.unique_integer()}",
          topic_id: data.topic.id,
          project_id: data.project.id,
          consumer_id: data.consumer.id,
          data: %{"id" => "bulk-1"},
          status: :processed
        })

      {:ok, event2} =
        Events.create(%{
          uid: "bulk-2-#{System.unique_integer()}",
          topic_id: data.topic.id,
          project_id: data.project.id,
          consumer_id: data.consumer.id,
          data: %{"id" => "bulk-2"},
          status: :unprocessed
        })

      assert {:ok, %{total_enqueued: 2, job_ids: job_ids}} =
               Events.bulk_replay(
                 project_id: data.project.id,
                 topic_ids: [data.topic.id]
               )

      for job_id <- job_ids do
        assert_receive {:bullmq_event, :completed, %{"jobId" => ^job_id}}, 5000
      end

      assert Events.get!(event1.id).status in [:unprocessed, :processing, :processed]
      assert Events.get!(event2.id).status in [:unprocessed, :processing, :processed]
    end
  end

  describe "create_with_attempts/1" do
    setup do
      org = organization_fixture()
      consumer = consumer_fixture(%{organization_id: org.id})
      project = project_fixture(%{organization_id: org.id})
      topic = topic_fixture(%{project_id: project.id})

      %{org: org, consumer: consumer, project: project, topic: topic}
    end

    test "event with matching subscriptions produces :pending Event and :scheduled DeliveryAttempts",
         %{
           project: project,
           topic: topic,
           consumer: consumer
         } do
      endpoint =
        endpoint_fixture(%{
          consumer_id: consumer.id,
          project_id: project.id,
          url: "http://localhost:4002/v1/webhooks",
          secret: "attemptsecret"
        })

      [subscription] =
        subscription_fixture(%{endpoint_id: endpoint.id, topics: [topic.id]})

      attrs = %{
        "uid" => "cwa-sub-#{System.unique_integer()}",
        "topic" => topic.name,
        "project_id" => project.id |> TypeID.to_string(),
        "consumer_id" => consumer.id |> TypeID.to_string(),
        "data" => %{"message" => "test"}
      }

      assert {:ok, %Event{} = event} = Events.create_with_attempts(attrs)
      assert event.status == :pending

      attempts =
        Repo.all(
          from(d in Whooks.DeliveryAttempts.DeliveryAttempt,
            where: d.event_id == ^event.id
          )
        )

      assert length(attempts) == 1
      attempt = hd(attempts)
      assert attempt.status == :scheduled
      assert attempt.subscription_id == subscription.id
    end

    test "event with 0 subscriptions produces :unprocessed Event and 0 attempts", %{
      project: project,
      topic: topic,
      consumer: consumer
    } do
      attrs = %{
        "uid" => "cwa-nosub-#{System.unique_integer()}",
        "topic" => topic.name,
        "project_id" => project.id |> TypeID.to_string(),
        "consumer_id" => consumer.id |> TypeID.to_string(),
        "data" => %{"message" => "nosub"}
      }

      assert {:ok, %Event{} = event} = Events.create_with_attempts(attrs)
      assert event.status == :unprocessed

      attempts =
        Repo.all(
          from(d in Whooks.DeliveryAttempts.DeliveryAttempt,
            where: d.event_id == ^event.id
          )
        )

      assert attempts == []
    end

    test "deduplicates by uid and returns existing event without creating duplicate attempts", %{
      project: project,
      topic: topic,
      consumer: consumer
    } do
      endpoint =
        endpoint_fixture(%{
          consumer_id: consumer.id,
          project_id: project.id,
          url: "http://localhost:4002/v1/webhooks",
          secret: "attemptsecret"
        })

      [_subscription] =
        subscription_fixture(%{endpoint_id: endpoint.id, topics: [topic.id]})

      uid = "cwa-dedup-#{System.unique_integer()}"

      attrs = %{
        "uid" => uid,
        "topic" => topic.name,
        "project_id" => project.id |> TypeID.to_string(),
        "consumer_id" => consumer.id |> TypeID.to_string(),
        "data" => %{"message" => "first"}
      }

      assert {:ok, %Event{id: id1}} = Events.create_with_attempts(attrs)
      assert {:ok, %Event{id: id2}} = Events.create_with_attempts(attrs)
      assert id1 == id2

      attempts =
        Repo.all(
          from(d in Whooks.DeliveryAttempts.DeliveryAttempt,
            where: d.event_id == ^id1
          )
        )

      assert length(attempts) == 1
    end
  end

  defp endpoint_url(port), do: "http://localhost:#{port}/v1/webhooks"
end
