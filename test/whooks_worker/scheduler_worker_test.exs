defmodule WhooksWorker.SchedulerWorkerTest do
  use Whooks.DataCase, async: false

  alias BullMQ.Job
  alias WhooksWorker.SchedulerWorker
  alias WhooksWorker.RetentionWorker
  alias Whooks.Repo
  alias Whooks.Events
  alias Whooks.Events.Event

  import Whooks.OrganizationsFixtures
  import Whooks.ProjectsFixtures
  import Whooks.ConsumersFixtures
  import Whooks.TopicsFixtures
  import Whooks.EventsFixtures

  setup_all do
    {:ok, queue_events} =
      BullMQ.QueueEvents.start_link(queue: "scheduler", connection: :bullmq_redis)

    %{queue_events: queue_events}
  end

  setup %{queue_events: queue_events} do
    BullMQ.QueueEvents.subscribe(queue_events, self())
    BullMQ.Queue.drain("scheduler", connection: :bullmq_redis)

    org = organization_fixture(%{name: "Scheduler Org", event_retention_days: 14})
    project = project_fixture(%{organization_id: org.id})
    consumer = consumer_fixture(%{organization_id: org.id})
    topic = topic_fixture(%{project_id: project.id})

    on_exit(fn ->
      BullMQ.Queue.drain("scheduler", connection: :bullmq_redis)
    end)

    %{org: org, project: project, consumer: consumer, topic: topic}
  end

  defp build_job(name, data) do
    %Job{
      id: "test_job_#{System.unique_integer([:positive])}",
      queue_name: "scheduler",
      name: name,
      data: data
    }
  end

  describe "process/1 schedule_organization_purges" do
    test "schedules a purge_organization job for each organization with retention" do
      job = build_job("schedule_organization_purges", %{})

      assert {:ok, %{scheduled_count: count}} = SchedulerWorker.process(job)
      assert count >= 1

      # Wait for background worker to complete the scheduled job on scheduler queue
      assert_receive {:bullmq_event, :completed, _}, 3000
    end
  end

  describe "process/1 purge_organization" do
    test "when events are purged, re-enqueues next batch with delay and returns status :re_enqueued",
         %{
           org: org,
           project: project,
           consumer: consumer,
           topic: topic
         } do
      old_time =
        DateTime.utc_now()
        |> DateTime.add(-20, :day)
        |> DateTime.truncate(:second)

      event =
        event_fixture(%{
          project_id: project.id,
          consumer_id: consumer.id,
          topic_id: topic.id
        })

      Repo.update_all(from(e in Event, where: e.id == ^event.id), set: [inserted_at: old_time])

      job =
        build_job("purge_organization", %{
          "organization_id" => org.id,
          "retention_days" => org.event_retention_days,
          "batch_size" => 10,
          "total_deleted" => 0
        })

      assert {:ok, result} = SchedulerWorker.process(job)
      assert result.organization_id == org.id
      assert result.deleted_in_batch == 1
      assert result.total_deleted == 1
      assert result.status == :re_enqueued

      # Event should now be deleted
      assert Repo.get(Event, event.id) == nil
    end

    test "when no events match, marks purge as completed", %{org: org} do
      job =
        build_job("purge_organization", %{
          "organization_id" => org.id,
          "retention_days" => org.event_retention_days,
          "batch_size" => 10,
          "total_deleted" => 5
        })

      assert {:ok, result} = SchedulerWorker.process(job)
      assert result.organization_id == org.id
      assert result.total_deleted == 5
      assert result.status == :completed
    end
  end

  describe "process/1 reconcile_stalled_events" do
    test "recovers stalled events", %{
      project: project,
      consumer: consumer,
      topic: topic
    } do
      stalled_time = DateTime.utc_now() |> DateTime.add(-600, :second)

      {:ok, event} =
        Events.create(%{
          uid: "stalled-scheduler-#{System.unique_integer()}",
          status: :pending,
          topic_id: topic.id,
          project_id: project.id,
          consumer_id: consumer.id,
          data: %{"test" => "scheduler_stalled"}
        })

      from(e in Event, where: e.id == ^event.id)
      |> Repo.update_all(set: [inserted_at: stalled_time])

      job = build_job("reconcile_stalled_events", %{})
      assert {:ok, %{reconciled_count: count}} = SchedulerWorker.process(job)
      assert count >= 1

      updated_event = Events.get!(event.id)
      assert updated_event.status == :unprocessed
    end
  end

  describe "process/1 unknown job" do
    test "returns error for unsupported job type" do
      job = build_job("unsupported_job_type", %{})
      assert {:error, "Unknown job type: unsupported_job_type"} = SchedulerWorker.process(job)
    end
  end

  describe "RetentionWorker backward compatibility" do
    test "delegates process/1 to SchedulerWorker" do
      job = build_job("unsupported_job_type", %{})
      assert {:error, "Unknown job type: unsupported_job_type"} = RetentionWorker.process(job)
    end
  end
end
