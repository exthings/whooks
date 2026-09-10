defmodule Whooks.Events.ReconcilerTest do
  use Whooks.DataCase, async: false

  alias Whooks.Events
  alias Whooks.Events.{Event, Reconciler}
  alias Whooks.Repo

  import Ecto.Query
  import Whooks.OrganizationsFixtures
  import Whooks.ConsumersFixtures
  import Whooks.TopicsFixtures
  import Whooks.ProjectsFixtures

  test "reconciler recovers pending events older than threshold" do
    org = organization_fixture()
    consumer = consumer_fixture(%{organization_id: org.id})
    project = project_fixture(%{organization_id: org.id})
    topic = topic_fixture(%{project_id: project.id})

    # Event stuck in pending created 10 minutes ago
    stalled_time = DateTime.utc_now() |> DateTime.add(-600, :second)

    {:ok, event} =
      Events.create(%{
        uid: "stalled-#{System.unique_integer()}",
        status: :pending,
        topic_id: topic.id,
        project_id: project.id,
        consumer_id: consumer.id,
        data: %{"test" => "stalled"}
      })

    # Backdate inserted_at
    from(e in Event, where: e.id == ^event.id)
    |> Repo.update_all(set: [inserted_at: stalled_time])

    # Run reconciler (threshold: 300 seconds)
    assert {:ok, %{reconciled_count: count}} = Reconciler.reconcile(threshold_seconds: 300)
    assert count >= 1

    # Since topic has no subscriptions, it should have been moved to no_subscribers
    updated_event = Events.get!(event.id)
    assert updated_event.status == :no_subscribers
  end
end
