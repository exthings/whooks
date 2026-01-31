defmodule Whooks.Endpoints do
  @moduledoc """
  The Endpoints context.
  """

  import Ecto.Query, warn: false
  alias Whooks.Repo

  alias Whooks.Endpoints.Endpoint

  alias Whooks.Topics
  alias Whooks.Topics.Topic
  alias Whooks.Common
  alias Whooks.Endpoints.Endpoint
  alias Whooks.Endpoints.Payloads.CreateEndpoint
  alias Whooks.Subscriptions.Subscription

  @doc """
  Returns the list of endpoints.

  ## Examples

      iex> list_endpoints()
      [%Endpoint{}, ...]

  """
  def list_endpoints do
    from(e in Endpoint,
      join: s in Subscription,
      on: e.id == s.endpoint_id,
      join: t in Topic,
      on: s.topic_id == t.id,
      preload: [subscriptions: :topic]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single endpoint.

  Raises `Ecto.NoResultsError` if the Endpoint does not exist.

  ## Examples

      iex> get_endpoint!(123)
      %Endpoint{}

      iex> get_endpoint!(456)
      ** (Ecto.NoResultsError)

  """
  def get_endpoint!(id) do
    Endpoint
    |> Repo.get!(id)
    |> Repo.preload(subscriptions: [:topic])
  end

  @doc """
  Creates a endpoint.

  ## Examples

      iex> create_endpoint(%{field: value})
      {:ok, %Endpoint{}}

      iex> create_endpoint(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_endpoint(%CreateEndpoint{} = payload) do
    with {:ok, topics} <- Topics.list_topics_by_names(payload.subscribe, payload.project_id) do
      %Endpoint{}
      |> Endpoint.changeset(%{
        uid: payload.uid,
        status: payload.status,
        url: payload.url,
        description: payload.description,
        headers: payload.headers,
        metadata: payload.metadata,
        consumer_id: payload.consumer_id,
        project_id: payload.project_id,
        subscriptions:
          Enum.map(topics, fn %Topic{} = topic ->
            %{
              topic_id: topic.id,
              status: "enabled"
            }
          end)
      })
      |> Repo.insert()
      |> Common.Ecto.preload(subscriptions: :topic)
    end
  end

  @doc """
  Updates a endpoint.

  ## Examples

      iex> update_endpoint(endpoint, %{field: new_value})
      {:ok, %Endpoint{}}

      iex> update_endpoint(endpoint, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_endpoint(%Endpoint{} = endpoint, attrs) do
    endpoint
    |> Endpoint.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a endpoint.

  ## Examples

      iex> delete_endpoint(endpoint)
      {:ok, %Endpoint{}}

      iex> delete_endpoint(endpoint)
      {:error, %Ecto.Changeset{}}

  """
  def delete_endpoint(%Endpoint{} = endpoint) do
    Repo.delete(endpoint)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking endpoint changes.

  ## Examples

      iex> change_endpoint(endpoint)
      %Ecto.Changeset{data: %Endpoint{}}

  """
  def change_endpoint(%Endpoint{} = endpoint, attrs \\ %{}) do
    Endpoint.changeset(endpoint, attrs)
  end
end
