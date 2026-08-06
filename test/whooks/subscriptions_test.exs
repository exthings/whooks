defmodule Whooks.SubscriptionsTest do
  use Whooks.DataCase

  alias Whooks.Subscriptions

  describe "subscriptions" do
    alias Whooks.Subscriptions.Subscription

    import Whooks.OrganizationsFixtures
    import Whooks.ConsumersFixtures
    import Whooks.TopicsFixtures
    import Whooks.EndpointsFixtures
    import Whooks.ProjectsFixtures
    import Whooks.SubscriptionsFixtures

    @invalid_attrs %{endpoint_id: "error"}

    setup do
      org = organization_fixture()
      consumer = consumer_fixture(%{organization_id: org.id})
      project = project_fixture(%{organization_id: org.id})
      topic = topic_fixture(%{project_id: project.id})

      endpoint =
        endpoint_fixture(%{
          consumer_id: consumer.id,
          project_id: project.id
        })

      %{org: org, consumer: consumer, topic: topic, endpoint: endpoint, project: project}
    end

    test "list_subscriptions/0 returns all subscriptions", data do
      subscription =
        subscription_fixture(%{endpoint_id: data.endpoint.id, topics: [data.topic.id]})

      assert Subscriptions.list_subscriptions() == subscription
    end

    test "get_subscription!/1 returns the subscription with given id", data do
      [subscription] =
        subscription_fixture(%{endpoint_id: data.endpoint.id, topics: [data.topic.id]})

      assert Subscriptions.get_subscription!(subscription.id) == subscription
    end

    test "create_subscription/1 with valid data and one topic", data do
      valid_attrs = %{
        endpoint_id: data.endpoint.id,
        topics: [data.topic.id]
      }

      assert {:ok, [%Subscription{} = subscription]} =
               Subscriptions.create_subscription(valid_attrs)

      assert subscription.status == :enabled
    end

    test "create_subscription/1 with valid data and two topics", data do
      topic = topic_fixture(%{project_id: data.project.id, name: "transaction.error"})

      valid_attrs = %{
        endpoint_id: data.endpoint.id,
        topics: [data.topic.id, topic.id]
      }

      assert {:ok, [%Subscription{} = subscription, %Subscription{} = subscription2]} =
               Subscriptions.create_subscription(valid_attrs)

      assert subscription.status == :enabled
      assert subscription2.status == :enabled
    end

    test "create_subscription/1 with invalid data returns error changeset", _data do
      assert {:error, %Ecto.Changeset{}} = Subscriptions.create_subscription(@invalid_attrs)
    end

    test "update_subscription/2 with valid data updates the subscription", data do
      [subscription] =
        subscription_fixture(%{endpoint_id: data.endpoint.id, topics: [data.topic.id]})

      update_attrs = %{status: :disabled}

      assert {:ok, %Subscription{} = subscription} =
               Subscriptions.update_subscription(subscription, update_attrs)

      assert subscription.status == :disabled
    end

    test "update_subscription/2 with invalid data returns error changeset", data do
      [subscription] =
        subscription_fixture(%{endpoint_id: data.endpoint.id, topics: [data.topic.id]})

      assert {:error, %Ecto.Changeset{}} =
               Subscriptions.update_subscription(subscription, @invalid_attrs)

      assert subscription == Subscriptions.get_subscription!(subscription.id)
    end

    test "delete_subscription/1 deletes the subscription", data do
      [subscription] =
        subscription_fixture(%{endpoint_id: data.endpoint.id, topics: [data.topic.id]})

      assert {:ok, %Subscription{}} = Subscriptions.delete_subscription(subscription)
      assert_raise Ecto.NoResultsError, fn -> Subscriptions.get_subscription!(subscription.id) end
    end

    test "change_subscription/1 returns a subscription changeset", data do
      [subscription] =
        subscription_fixture(%{endpoint_id: data.endpoint.id, topics: [data.topic.id]})

      assert %Ecto.Changeset{} = Subscriptions.change_subscription(subscription)
    end
  end
end
