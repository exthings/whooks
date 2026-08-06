defmodule Whooks.ConsumersTest do
  use Whooks.DataCase

  alias Whooks.Consumers

  describe "consumers" do
    alias Whooks.Consumers.Consumer

    import Whooks.ConsumersFixtures

    @invalid_attrs %{name: nil, metadata: nil, uid: nil}

    test "list/0 returns all consumers" do
      consumer = consumer_fixture()
      assert Consumers.list() == [consumer]
    end

    test "get!/1 returns the consumer with given id" do
      consumer = consumer_fixture()
      assert Consumers.get!(consumer.id) == consumer
    end

    test "create/1 with valid data creates a consumer" do
      valid_attrs = %{name: "some name", metadata: %{}, uid: "some uid"}

      assert {:ok, %Consumer{} = consumer} = Consumers.create(valid_attrs)
      assert consumer.name == "some name"
      assert consumer.metadata == %{}
      assert consumer.uid == "some uid"
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Consumers.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the consumer" do
      consumer = consumer_fixture()
      update_attrs = %{name: "some updated name", metadata: %{}, uid: "some updated uid"}

      assert {:ok, %Consumer{} = consumer} = Consumers.update(consumer, update_attrs)
      assert consumer.name == "some updated name"
      assert consumer.metadata == %{}
      assert consumer.uid == "some updated uid"
    end

    test "update/2 with invalid data returns error changeset" do
      consumer = consumer_fixture()
      assert {:error, %Ecto.Changeset{}} = Consumers.update(consumer, @invalid_attrs)
      assert consumer == Consumers.get!(consumer.id)
    end

    test "delete/1 deletes the consumer" do
      consumer = consumer_fixture()
      assert {:ok, %Consumer{}} = Consumers.delete(consumer)
      assert_raise Ecto.NoResultsError, fn -> Consumers.get!(consumer.id) end
    end

    test "change/1 returns a consumer changeset" do
      consumer = consumer_fixture()
      assert %Ecto.Changeset{} = Consumers.change(consumer)
    end
  end
end
