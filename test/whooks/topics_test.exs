defmodule Whooks.TopicsTest do
  use Whooks.DataCase

  alias Whooks.Topics

  describe "topics" do
    alias Whooks.Topics.Topic

    import Whooks.TopicsFixtures
    import Whooks.ProjectsFixtures

    setup do
      project = project_fixture()

      %{project: project}
    end

    test "list_topics/0 returns all topics", %{project: project} do
      topic = topic_fixture(%{project_id: project.id})
      assert Topics.list_topics() == [topic]
    end

    test "get_by_id!/1 returns the topic with given id", %{project: project} do
      topic = topic_fixture(%{project_id: project.id})
      assert Topics.get_by_id!(topic.id) == topic
    end

    test "create_topic/1 with valid data creates a topic", %{project: project} do
      valid_attrs = %{
        project_id: project.id,
        name: "transaction.paid",
        status: "enabled",
        description: "Transaction paid event",
        json_schema: %{"type" => "object", "properties" => %{"id" => %{"type" => "string"}}}
      }

      assert {:ok, %Topic{} = topic} = Topics.create_topic(valid_attrs)
      assert topic.name == valid_attrs.name
      assert topic.status == valid_attrs.status
      assert topic.description == valid_attrs.description
      assert topic.json_schema == valid_attrs.json_schema
    end

    test "create_topic/1 with invalid name returns error changeset", %{project: project} do
      invalid_attrs = %{
        project_id: project.id,
        name: "transaction paid",
        status: "enabled",
        description: "Transaction paid event",
        json_schema: %{"type" => "object", "properties" => %{"id" => %{"type" => "string"}}}
      }

      assert {:error,
              %Ecto.Changeset{errors: [name: {"invalid dot notation", [validation: :format]}]}} =
               Topics.create_topic(invalid_attrs)
    end

    test "update_topic/2 with valid data updates the topic", %{project: project} do
      topic = topic_fixture(%{project_id: project.id})

      update_attrs = %{
        name: "transaction.pending",
        status: "enabled",
        description: "Transaction pending event",
        json_schema: %{"type" => "object", "properties" => %{"id" => %{"type" => "string"}}}
      }

      assert {:ok, %Topic{} = topic} = Topics.update_topic(topic, update_attrs)
      assert topic.name == update_attrs.name
      assert topic.status == update_attrs.status
      assert topic.description == update_attrs.description
      assert topic.json_schema == update_attrs.json_schema
    end

    test "update_topic/2 with invalid data returns error changeset", %{project: project} do
      topic = topic_fixture(%{project_id: project.id})

      invalid_attrs = %{
        name: "transaction paid",
        status: "enabled",
        description: "Transaction paid event",
        json_schema: %{"type" => "object", "properties" => %{"id" => %{"type" => "string"}}}
      }

      assert {:error, %Ecto.Changeset{}} = Topics.update_topic(topic, invalid_attrs)
    end

    test "delete_topic/1 deletes the topic", %{project: project} do
      topic = topic_fixture(%{project_id: project.id})
      assert {:ok, %Topic{}} = Topics.delete_topic(topic)
      assert_raise Ecto.NoResultsError, fn -> Topics.get_by_id!(topic.id) end
    end

    test "change_topic/1 returns a topic changeset", %{project: project} do
      topic = topic_fixture(%{project_id: project.id})
      assert %Ecto.Changeset{} = Topics.change_topic(topic)
    end
  end
end
