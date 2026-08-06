defmodule Whooks.ConsumersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Whooks.Consumers` context.
  """

  @doc """
  Generate a unique consumer uid.
  """
  def unique_consumer_uid, do: "some uid#{System.unique_integer([:positive])}"

  @doc """
  Generate a consumer.
  """
  def consumer_fixture(attrs \\ %{}) do
    {:ok, consumer} =
      attrs
      |> Enum.into(%{
        metadata: %{},
        name: "some name",
        uid: unique_consumer_uid()
      })
      |> Whooks.Consumers.create()

    consumer
  end
end
