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
      name: consumer.name,
      uid: consumer.uid,
      metadata: consumer.metadata,
      inserted_at: consumer.inserted_at,
      updated_at: consumer.updated_at,
      endpoints: map_assoc(consumer.endpoints)
    }
  end

  defp serialize(%DeliveryAttempt{} = delivery_attempt) do
    %{
      id: delivery_attempt.id,
      status: delivery_attempt.status,
      inserted_at: delivery_attempt.inserted_at,
      req_headers: delivery_attempt.req_headers,
      res_headers: delivery_attempt.res_headers,
      res_status: delivery_attempt.res_status,
      res_body: delivery_attempt.res_body,
      latency_ms: delivery_attempt.latency_ms
    }
  end

  defp serialize(%Endpoint{} = endpoint) do
    %{
      id: endpoint.id,
      uid: endpoint.uid,
      status: endpoint.status,
      url: endpoint.url,
      description: endpoint.description,
      headers: endpoint.headers,
      metadata: endpoint.metadata,
      secret: endpoint.secret,
      old_secrets: endpoint.old_secrets,
      inserted_at: endpoint.inserted_at,
      updated_at: endpoint.updated_at,
      consumer: map_assoc(endpoint.consumer),
      project: map_assoc(endpoint.project),
      subscriptions: map_assoc(endpoint.subscriptions)
    }
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
      consumer: map_assoc(event.consumer),
      project: map_assoc(event.project),
      attempts: map_assoc(event.delivery_attempts)
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

  defp serialize(%Subscription{} = subscription) do
    %{
      id: subscription.id,
      inserted_at: subscription.inserted_at,
      updated_at: subscription.updated_at,
      status: subscription.status,
      topic: map_assoc(subscription.topic)
    }
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

  defp serialize(%Flop.Meta{} = meta) do
    %{
      current_page: meta.current_page,
      page_size: meta.page_size,
      total_count: meta.total_count,
      total_pages: meta.total_pages,
      has_next_page: meta.has_next_page?,
      has_previous_page: meta.has_previous_page?,
      next_page: meta.next_page,
      previous_page: meta.previous_page,
      filters: meta.flop.filters |> Enum.map(&map_filter/1)
    }
  end

  defp map_filter(filter) do
    %{
      field: filter.field,
      op: filter.op,
      value: filter.value
    }
  end

  defp map_assoc(%Ecto.Association.NotLoaded{}), do: nil
  defp map_assoc(data) when is_list(data), do: for(item <- data, do: serialize(item))
  defp map_assoc(data), do: serialize(data)
end
