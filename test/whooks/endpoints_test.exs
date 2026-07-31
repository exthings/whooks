defmodule Whooks.EndpointsTest do
  use Whooks.DataCase

  alias Whooks.Endpoints

  describe "endpoints" do
    alias Whooks.Endpoints.Endpoint

    import Whooks.EndpointsFixtures
    import Whooks.OrganizationsFixtures
    import Whooks.ConsumersFixtures
    import Whooks.ProjectsFixtures
    import Whooks.TopicsFixtures

    setup do
      org = organization_fixture()
      consumer = consumer_fixture(%{organization_id: org.id})
      project = project_fixture(%{organization_id: org.id})
      topic = topic_fixture(%{project_id: project.id})

      %{org: org, consumer: consumer, project: project, topic: topic}
    end

    test "list_endpoints/0 returns all endpoints", %{
      consumer: consumer,
      project: project,
      topic: topic
    } do
      endpoint =
        endpoint_fixture(%{
          consumer_id: consumer.id,
          project_id: project.id,
          subscribe: [topic.name]
        })

      assert Endpoints.list_endpoints() == [endpoint]
    end

    test "get_endpoint!/1 returns the endpoint with given id", %{
      consumer: consumer,
      project: project,
      topic: topic
    } do
      endpoint =
        endpoint_fixture(%{
          consumer_id: consumer.id,
          project_id: project.id,
          subscribe: [topic.name]
        })

      assert Endpoints.get_endpoint!(endpoint.id) == endpoint
    end

    test "create_endpoint/1 with valid data creates a endpoint", %{
      consumer: consumer,
      project: project,
      topic: topic
    } do
      valid_attrs = %{
        consumer_id: consumer.id,
        project_id: project.id,
        subscribe: [topic.name],
        status: "enabled",
        description: "some description",
        metadata: %{},
        uid: "fot2qfewgu57whtahnpnlq4s",
        url: "some url",
        headers: %{},
        secret: "some secret",
        old_secrets: %{}
      }

      assert {:ok, %Endpoint{} = endpoint} = Endpoints.create_endpoint(valid_attrs)
      assert endpoint.status == :enabled
      assert endpoint.description == "some description"
      assert endpoint.metadata == %{}
      assert endpoint.uid == "fot2qfewgu57whtahnpnlq4s"
      assert endpoint.url == "some url"
      assert endpoint.headers == %{}
      assert endpoint.secret == nil
      assert endpoint.old_secrets == nil
    end

    test "create_endpoint/1 with invalid data returns error changeset", %{
      consumer: consumer,
      project: project,
      topic: topic
    } do
      invalid_attrs = %{
        consumer_id: consumer.id,
        project_id: project.id,
        subscribe: [topic.name],
        status: nil,
        description: nil,
        metadata: nil,
        uid: nil,
        url: nil,
        headers: nil,
        secret: nil,
        old_secrets: nil
      }

      assert {:error, %Ecto.Changeset{}} = Endpoints.create_endpoint(invalid_attrs)
    end

    test "update_endpoint/2 with valid data updates the endpoint", %{
      consumer: consumer,
      project: project,
      topic: topic
    } do
      endpoint =
        endpoint_fixture(%{
          consumer_id: consumer.id,
          project_id: project.id,
          subscribe: [topic.name]
        })

      update_attrs = %{
        status: "disabled",
        description: "some updated description",
        metadata: %{"test" => "abc"}
      }

      assert {:ok, %Endpoint{} = endpoint} = Endpoints.update_endpoint(endpoint, update_attrs)
      assert endpoint.status == :disabled
      assert endpoint.description == "some updated description"
      assert endpoint.metadata == %{"test" => "abc"}
    end

    test "update_endpoint/2 with invalid data returns error changeset", %{
      consumer: consumer,
      project: project,
      topic: topic
    } do
      endpoint =
        endpoint_fixture(%{
          consumer_id: consumer.id,
          project_id: project.id,
          subscribe: [topic.name]
        })

      invalid_attrs = %{
        status: "abc"
      }

      assert {:error, %Ecto.Changeset{}} = Endpoints.update_endpoint(endpoint, invalid_attrs)
      assert endpoint == Endpoints.get_endpoint!(endpoint.id)
    end

    test "change_endpoint/1 returns a endpoint changeset", %{
      consumer: consumer,
      project: project,
      topic: topic
    } do
      endpoint =
        endpoint_fixture(%{
          consumer_id: consumer.id,
          project_id: project.id,
          subscribe: [topic.name]
        })

      assert %Ecto.Changeset{} = Endpoints.change_endpoint(endpoint)
    end
  end
end
