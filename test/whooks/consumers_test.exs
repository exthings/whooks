defmodule Whooks.ConsumersTest do
  use Whooks.DataCase

  alias Whooks.Consumers

  describe "consumers" do
    alias Whooks.Consumers.Consumer

    import Whooks.ConsumersFixtures

    @invalid_attrs %{name: nil, metadata: nil, uid: nil}

    test "list_consumers/0 returns all consumers" do
      consumer = consumer_fixture()
      assert Consumers.list_consumers() == [consumer]
    end

    test "get_consumer!/1 returns the consumer with given id" do
      consumer = consumer_fixture()
      assert Consumers.get_consumer!(consumer.id) == consumer
    end

    test "create_consumer/1 with valid data creates a consumer" do
      valid_attrs = %{name: "some name", metadata: %{}, uid: "some uid"}

      assert {:ok, %Consumer{} = consumer} = Consumers.create_consumer(valid_attrs)
      assert consumer.name == "some name"
      assert consumer.metadata == %{}
      assert consumer.uid == "some uid"
    end

    test "create_consumer/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Consumers.create_consumer(@invalid_attrs)
    end

    test "update_consumer/2 with valid data updates the consumer" do
      consumer = consumer_fixture()
      update_attrs = %{name: "some updated name", metadata: %{}, uid: "some updated uid"}

      assert {:ok, %Consumer{} = consumer} = Consumers.update_consumer(consumer, update_attrs)
      assert consumer.name == "some updated name"
      assert consumer.metadata == %{}
      assert consumer.uid == "some updated uid"
    end

    test "update_consumer/2 with invalid data returns error changeset" do
      consumer = consumer_fixture()
      assert {:error, %Ecto.Changeset{}} = Consumers.update_consumer(consumer, @invalid_attrs)
      assert consumer == Consumers.get_consumer!(consumer.id)
    end

    test "delete_consumer/1 deletes the consumer" do
      consumer = consumer_fixture()
      assert {:ok, %Consumer{}} = Consumers.delete_consumer(consumer)
      assert_raise Ecto.NoResultsError, fn -> Consumers.get_consumer!(consumer.id) end
    end

    test "change_consumer/1 returns a consumer changeset" do
      consumer = consumer_fixture()
      assert %Ecto.Changeset{} = Consumers.change_consumer(consumer)
    end
  end
end
