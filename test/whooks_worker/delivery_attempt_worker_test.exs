defmodule WhooksWorker.DeliveryAttemptWorkerTest do
  use Whooks.DataCase, async: false

  alias BullMQ.Job
  alias Whooks.Repo
  alias Whooks.Events
  alias Whooks.DeliveryAttempts
  alias Whooks.DeliveryAttempts.DeliveryAttempt
  alias WhooksWorker.DeliveryAttemptWorker

  import Whooks.OrganizationsFixtures
  import Whooks.ProjectsFixtures
  import Whooks.ConsumersFixtures
  import Whooks.TopicsFixtures
  import Whooks.EndpointsFixtures
  import Whooks.SubscriptionsFixtures

  setup do
    bypass = Bypass.open()

    org = organization_fixture()
    project = project_fixture(%{organization_id: org.id})
    consumer = consumer_fixture(%{organization_id: org.id})
    topic = topic_fixture(%{project_id: project.id})

    endpoint =
      endpoint_fixture(%{
        consumer_id: consumer.id,
        project_id: project.id,
        url: "http://localhost:#{bypass.port}/v1/webhooks",
        secret: "whsec_wk743dme4lua6scxvm4gaoj5"
      })

    [subscription] =
      subscription_fixture(%{endpoint_id: endpoint.id, topics: [topic.id]})

    %{
      bypass: bypass,
      org: org,
      project: project,
      consumer: consumer,
      topic: topic,
      endpoint: endpoint,
      subscription: subscription
    }
  end

  defp build_attempt_job(attempt, event, endpoint, opts \\ %{}) do
    %Job{
      id: "job_#{System.unique_integer([:positive])}",
      queue_name: "deliveries",
      name: "attempt",
      attempts_made: Map.get(opts, :attempts_made, 0),
      opts: %{"attempts" => Map.get(opts, :max_attempts, 3)},
      data: %{
        "attempt_id" => to_string(attempt.id),
        "event_id" => to_string(event.id),
        "subscription_id" => to_string(attempt.subscription_id),
        "topic" => "test.event",
        "data" => event.data,
        "url" => endpoint.url,
        "secret" => endpoint.secret
      }
    }
  end

  describe "process/1 attempt" do
    test "successful HTTP dispatch transitions attempt to :success and marks event :processed", %{
      bypass: bypass,
      project: project,
      consumer: consumer,
      topic: topic,
      endpoint: endpoint,
      subscription: subscription
    } do
      Bypass.expect_once(bypass, "POST", "/v1/webhooks", fn conn ->
        Plug.Conn.resp(conn, 200, Jason.encode!(%{status: "ok"}))
      end)

      {:ok, event} =
        Events.create(%{
          uid: "worker-success-#{System.unique_integer()}",
          topic_id: topic.id,
          project_id: project.id,
          consumer_id: consumer.id,
          data: %{"message" => "success test"},
          status: :pending
        })

      attempt_id = DeliveryAttempt.gen_id() |> TypeID.to_string()

      {:ok, attempt} =
        %DeliveryAttempt{}
        |> DeliveryAttempt.create_changeset(%{
          id: attempt_id,
          event_id: event.id,
          subscription_id: subscription.id,
          status: :scheduled
        })
        |> Repo.insert()

      job = build_attempt_job(attempt, event, endpoint)

      assert {:ok, result} = DeliveryAttemptWorker.process(job)
      assert result.status == :success

      updated_attempt = DeliveryAttempts.get!(attempt.id)
      assert updated_attempt.status == :success
      assert updated_attempt.res_status == 200

      updated_event = Events.get!(event.id)
      assert updated_event.status == :processed
    end

    test "failed HTTP dispatch with remaining attempts transitions attempt to :retry and event remains :processing",
         %{
           bypass: bypass,
           project: project,
           consumer: consumer,
           topic: topic,
           endpoint: endpoint,
           subscription: subscription
         } do
      Bypass.expect_once(bypass, "POST", "/v1/webhooks", fn conn ->
        Plug.Conn.resp(conn, 500, Jason.encode!(%{error: "internal server error"}))
      end)

      {:ok, event} =
        Events.create(%{
          uid: "worker-retry-#{System.unique_integer()}",
          topic_id: topic.id,
          project_id: project.id,
          consumer_id: consumer.id,
          data: %{"message" => "retry test"},
          status: :pending
        })

      attempt_id = DeliveryAttempt.gen_id() |> TypeID.to_string()

      {:ok, attempt} =
        %DeliveryAttempt{}
        |> DeliveryAttempt.create_changeset(%{
          id: attempt_id,
          event_id: event.id,
          subscription_id: subscription.id,
          status: :scheduled
        })
        |> Repo.insert()

      job = build_attempt_job(attempt, event, endpoint, %{attempts_made: 0, max_attempts: 3})

      assert {:error, %{failed: true}} = DeliveryAttemptWorker.process(job)

      updated_attempt = DeliveryAttempts.get!(attempt.id)
      assert updated_attempt.status == :retry
      assert updated_attempt.res_status == 500

      updated_event = Events.get!(event.id)
      # Event should be :processing since attempt is in retry (not yet terminal)
      assert updated_event.status == :processing
    end

    test "failed HTTP dispatch with exhausted attempts transitions attempt to :failed and marks event :processed",
         %{
           bypass: bypass,
           project: project,
           consumer: consumer,
           topic: topic,
           endpoint: endpoint,
           subscription: subscription
         } do
      Bypass.expect_once(bypass, "POST", "/v1/webhooks", fn conn ->
        Plug.Conn.resp(conn, 500, Jason.encode!(%{error: "terminal error"}))
      end)

      {:ok, event} =
        Events.create(%{
          uid: "worker-failed-#{System.unique_integer()}",
          topic_id: topic.id,
          project_id: project.id,
          consumer_id: consumer.id,
          data: %{"message" => "terminal fail test"},
          status: :pending
        })

      attempt_id = DeliveryAttempt.gen_id() |> TypeID.to_string()

      {:ok, attempt} =
        %DeliveryAttempt{}
        |> DeliveryAttempt.create_changeset(%{
          id: attempt_id,
          event_id: event.id,
          subscription_id: subscription.id,
          status: :scheduled
        })
        |> Repo.insert()

      # attempts_made = 2 + 1 = 3 >= max_attempts (3)
      job = build_attempt_job(attempt, event, endpoint, %{attempts_made: 2, max_attempts: 3})

      assert {:error, %{failed: true}} = DeliveryAttemptWorker.process(job)

      updated_attempt = DeliveryAttempts.get!(attempt.id)
      assert updated_attempt.status == :failed
      assert updated_attempt.res_status == 500

      updated_event = Events.get!(event.id)
      # All attempts are now terminal (:failed), so event is marked :processed
      assert updated_event.status == :processed
    end

    test "returns error for unknown job name" do
      job = %Job{
        id: "job_unknown",
        queue_name: "deliveries",
        name: "unknown_job",
        data: %{}
      }

      assert {:error, "Unknown job type: unknown_job"} = DeliveryAttemptWorker.process(job)
    end
  end
end
