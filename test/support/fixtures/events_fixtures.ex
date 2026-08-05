defmodule Whooks.EventsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Whooks.Events` context.
  """

  @doc """
  Generate a unique event uid.
  """
  def unique_event_uid, do: "some uid#{System.unique_integer([:positive])}"

  @doc """
  Generate a event.
  """
  def event_fixture(attrs \\ %{}) do
    {:ok, event} =
      attrs
      |> Enum.into(%{
        uid: unique_event_uid(),
        data: %{"name" => "event1"},
        tags: ["tag1", "tag2"],
        metadata: %{"meta" => "data"}
      })
      |> Whooks.Events.create()

    event
  end
end
