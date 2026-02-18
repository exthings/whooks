defmodule WhooksWeb.UI.Admin.EventController do
  use WhooksWeb, :controller

  alias Whooks.Events
  alias Whooks.Common

  require Logger

  def show(conn, params) do
    with {:ok, event} <- Events.get(params["id"]) do
      conn
      |> assign_prop(:event, serialize_event(event))
      |> render_inertia("events/show")
    end
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
      topic: serialize_topic(event.topic),
      project: serialize_project(event.project),
      consumer: serialize_consumer(event.consumer),
      attempts: serialize_attempts(event.delivery_attempts)
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

  defp serialize_consumer(consumer) do
    %{
      id: consumer.id,
      uid: consumer.uid,
      name: consumer.name,
      metadata: consumer.metadata,
      inserted_at: consumer.inserted_at,
      updated_at: consumer.updated_at,
      endpoints: Common.Ecto.map_if_loaded(consumer.endpoints, &serialize_endpoint/1)
    }
  end

  defp serialize_endpoint(endpoint) do
    %{
      id: endpoint.id,
      uid: endpoint.uid,
      status: endpoint.status,
      url: endpoint.url,
      description: endpoint.description,
      headers: endpoint.headers,
      metadata: endpoint.metadata,
      inserted_at: endpoint.inserted_at,
      updated_at: endpoint.updated_at
    }
  end

  defp serialize_topic(topic) do
    %{
      id: topic.id,
      name: topic.name
    }
  end

  defp serialize_attempts(attempts) do
    for attempt <- attempts, do: serialize_attempt(attempt)
  end

  defp serialize_attempt(attempt) do
    %{
      id: attempt.id,
      status: attempt.status,
      inserted_at: attempt.inserted_at,
      res_headers: attempt.res_headers,
      res_status: attempt.res_status,
      res_body: attempt.res_body,
      latency_ms: attempt.latency_ms
    }
  end
end
