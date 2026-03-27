defmodule Whooks.Serializer do
  @doc """
  Converts a schema or list of schemas into a plain map
  ready for Jason to encode.
  """

  alias Whooks.Consumers.Consumer
  alias Whooks.DeliveryAttempts.DeliveryAttempt
  alias Whooks.Endpoints.Endpoint
  alias Whooks.Events.Event
  alias Whooks.Organizations.Organization
  alias Whooks.Projects.Project
  alias Whooks.Subscriptions.Subscription
  alias Whooks.Topics.Topic

  def to_map(data, opts \\ [])

  def to_map(data, _opts) when is_list(data),
    do: for(item <- data, do: serialize(item))

  def to_map(data, _opts), do: serialize(data)

  defp serialize(%Consumer{} = consumer) do
    %{
      id: consumer.id,
      name: consumer.name
    }
  end

  defp serialize(%DeliveryAttempt{} = _delivery_attempt) do
    %{}
  end

  defp serialize(%Endpoint{} = _endpoint) do
    %{}
  end

  defp serialize(%Event{} = event) do
    %{
      id: event.id,
      inserted_at: event.inserted_at,
      updated_at: event.updated_at,
      uid: event.uid,
      status: event.status,
      data: event.data,
      metadata: event.metadata,
      tags: event.tags,
      topic: map_assoc(event.topic),
      consumer: map_assoc(event.consumer)
    }
  end

  defp serialize(%Organization{} = organization) do
    %{
      id: organization.id,
      inserted_at: organization.inserted_at,
      updated_at: organization.updated_at,
      name: organization.name
    }
  end

  defp serialize(%Project{} = project) do
    %{
      id: project.id,
      uid: project.uid,
      inserted_at: project.inserted_at,
      updated_at: project.updated_at,
      name: project.name,
      status: project.status,
      metadata: project.metadata,
      organization: map_assoc(project.organization),
      topics: map_assoc(project.topics)
    }
  end

  defp serialize(%Subscription{} = _subscription) do
    %{}
  end

  defp serialize(%Topic{} = topic) do
    %{
      id: topic.id,
      name: topic.name,
      status: topic.status,
      description: topic.description,
      json_schema: topic.json_schema,
      example: topic.example,
      inserted_at: topic.inserted_at,
      updated_at: topic.updated_at
    }
  end

  defp map_assoc(%Ecto.Association.NotLoaded{}), do: nil
  defp map_assoc(data) when is_list(data), do: for(item <- data, do: serialize(item))
  defp map_assoc(data), do: serialize(data)
end
