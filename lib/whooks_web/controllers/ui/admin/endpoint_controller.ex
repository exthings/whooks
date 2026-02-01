defmodule WhooksWeb.UI.Admin.EndpointController do
  use WhooksWeb, :controller

  alias Whooks.Common
  alias Whooks.Events
  alias Whooks.Endpoints

  def show(conn, %{"id" => id}) do
    with {:ok, endpoint} <- Endpoints.get_by_id(id) do
      conn
      |> assign_prop(:endpoint, serialize_endpoint(endpoint))
      |> assign_prop(
        :events,
        inertia_defer(fn ->
          {:ok, {events, meta}} = Events.list_by_endpoint(%{}, endpoint.id)
          %{data: for(event <- events, do: serialize_event(event)), meta: meta}
        end)
      )
      |> render_inertia("endpoints/show")
    end
  end

  defp serialize_endpoint(endpoint) do
    %{
      id: endpoint.id,
      uid: endpoint.uid,
      inserted_at: endpoint.inserted_at,
      updated_at: endpoint.updated_at,
      status: endpoint.status,
      url: endpoint.url,
      description: endpoint.description,
      headers: endpoint.headers,
      metadata: endpoint.metadata,
      secret: endpoint.secret,
      old_secrets: endpoint.old_secrets,
      consumer_id: endpoint.consumer_id,
      project_id: endpoint.project_id,
      consumer: Common.Ecto.map_if_loaded(endpoint.consumer, &serialize_consumer/1),
      project: Common.Ecto.map_if_loaded(endpoint.project, &serialize_project/1),
      subscriptions:
        Common.Ecto.map_if_loaded(
          endpoint.subscriptions,
          &serialize_subscription/1
        )
    }
  end

  defp serialize_event(event) do
    %{
      id: event.id,
      inserted_at: event.inserted_at,
      updated_at: event.updated_at,
      uid: event.uid,
      status: event.status,
      data: event.data,
      metadata: event.metadata,
      tags: event.tags,
      topic: serialize_topic(event.topic)
    }
  end

  defp serialize_consumer(consumer) do
    %{
      id: consumer.id,
      uid: consumer.uid,
      name: consumer.name,
      metadata: consumer.metadata,
      inserted_at: consumer.inserted_at,
      updated_at: consumer.updated_at
    }
  end

  defp serialize_project(project) do
    %{
      id: project.id,
      inserted_at: project.inserted_at,
      updated_at: project.updated_at,
      name: project.name
    }
  end

  defp serialize_subscription(subscription) do
    %{
      id: subscription.id,
      inserted_at: subscription.inserted_at,
      updated_at: subscription.updated_at,
      status: subscription.status,
      topic: Common.Ecto.map_if_loaded(subscription.topic, &serialize_topic/1)
    }
  end

  defp serialize_topic(topic) do
    %{
      id: topic.id,
      inserted_at: topic.inserted_at,
      updated_at: topic.updated_at,
      name: topic.name,
      status: topic.status,
      description: topic.description,
      json_schema: topic.json_schema
    }
  end
end
