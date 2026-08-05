defmodule Whooks.TopicsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Whooks.Topics` context.
  """

  @doc """
  Generate a topic.
  """
  def topic_fixture(attrs \\ %{}) do
    {:ok, topic} =
      attrs
      |> Enum.into(%{
        name: "transaction.approved",
        description: "Transaction approved event",
        json_schema: %{"type" => "object", "properties" => %{"id" => %{"type" => "string"}}},
        status: "enabled",
        project_id: attrs[:project_id]
      })
      |> Whooks.Topics.create()

    topic
  end
end
