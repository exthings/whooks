defmodule Whooks.TopicsTest do
  use Whooks.DataCase

  alias Whooks.Topics

  describe "topics" do
    alias Whooks.Topics.Topic

    import Whooks.OrganizationsFixtures
    import Whooks.ProjectsFixtures
    import Whooks.TopicsFixtures

    setup do
      org = organization_fixture()
      project = project_fixture(%{organization_id: org.id})

      %{project: project}
    end

    test "list/0 returns all topics", %{project: project} do
      topic = topic_fixture(%{project_id: project.id})
      assert Topics.list() == [topic]
    end

    test "get!/1 returns the topic with given id", %{project: project} do
      topic = topic_fixture(%{project_id: project.id})
      assert Topics.get!(topic.id) == topic
    end

    test "create/1 with valid data creates a topic", %{project: project} do
      valid_attrs = %{
        project_id: project.id,
        name: "transaction.paid",
        status: "enabled",
        description: "Transaction paid event",
        json_schema: %{"type" => "object", "properties" => %{"id" => %{"type" => "string"}}}
      }

      assert {:ok, %Topic{} = topic} = Topics.create(valid_attrs)
      assert topic.name == valid_attrs.name
      assert topic.status == valid_attrs.status
      assert topic.description == valid_attrs.description
      assert topic.json_schema == valid_attrs.json_schema
    end

    test "create/1 with invalid name returns error changeset", %{project: project} do
      invalid_attrs = %{
        project_id: project.id,
        name: "transaction paid",
        status: "enabled",
        description: "Transaction paid event",
        json_schema: %{"type" => "object", "properties" => %{"id" => %{"type" => "string"}}}
      }

      assert {:error,
              %Ecto.Changeset{errors: [name: {"invalid dot notation", [validation: :format]}]}} =
               Topics.create(invalid_attrs)
    end

    test "update/2 with valid data updates the topic", %{project: project} do
      topic = topic_fixture(%{project_id: project.id})

      update_attrs = %{
        name: "transaction.pending",
        status: "enabled",
        description: "Transaction pending event",
        json_schema: %{"type" => "object", "properties" => %{"id" => %{"type" => "string"}}}
      }

      assert {:ok, %Topic{} = topic} = Topics.update(topic, update_attrs)
      assert topic.name == update_attrs.name
      assert topic.status == update_attrs.status
      assert topic.description == update_attrs.description
      assert topic.json_schema == update_attrs.json_schema
    end

    test "update/2 with invalid data returns error changeset", %{project: project} do
      topic = topic_fixture(%{project_id: project.id})

      invalid_attrs = %{
        name: "transaction paid",
        status: "enabled",
        description: "Transaction paid event",
        json_schema: %{"type" => "object", "properties" => %{"id" => %{"type" => "string"}}}
      }

      assert {:error, %Ecto.Changeset{}} = Topics.update(topic, invalid_attrs)
    end

    test "delete/1 deletes the topic", %{project: project} do
      topic = topic_fixture(%{project_id: project.id})
      assert {:ok, %Topic{}} = Topics.delete(topic)
      assert_raise Ecto.NoResultsError, fn -> Topics.get!(topic.id) end
    end

    test "change/1 returns a topic changeset", %{project: project} do
      topic = topic_fixture(%{project_id: project.id})
      assert %Ecto.Changeset{} = Topics.change(topic)
    end
  end
end
