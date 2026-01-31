defmodule WhooksWeb.V1.EventJSON do
  alias Whooks.Events.Event

  @doc """
  Renders a list of events.
  """
  def index(%{events: events}) do
    %{data: for(event <- events, do: data(event))}
  end

  @doc """
  Renders a single event.
  """
  def show(%{event: event}) do
    %{data: data(event)}
  end

  defp data(%Event{} = event) do
    %{
      id: event.id,
      inserted_at: event.inserted_at,
      updated_at: event.updated_at,
      status: event.status,
      uid: event.uid,
      data: event.data,
      tags: event.tags,
      metadata: event.metadata,
      topic_id: event.topic_id,
      project_id: event.project_id,
      consumer_id: event.consumer_id
    }
  end
end
