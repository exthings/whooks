defmodule Whooks.Endpoints do
  @moduledoc """
  The Endpoints context.
  """
  @behaviour Bodyguard.Policy

  import Ecto.Query, warn: false
  alias Whooks.Repo

  alias Whooks.Endpoints.Endpoint

  alias Whooks.Topics
  alias Whooks.Topics.Topic
  alias Whooks.Common
  alias Whooks.Endpoints.Endpoint
  alias Whooks.Subscriptions.Subscription
  alias Whooks.Auth.Scope

  @doc """
  Returns the list of endpoints.

  ## Examples

      iex> list()
      [%Endpoint{}, ...]

  """
  def list do
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

      iex> get!(123)
      %Endpoint{}

      iex> get!(456)
      ** (Ecto.NoResultsError)

  """
  def get!(id) do
    Endpoint
    |> Repo.get!(id)
    |> Repo.preload(subscriptions: [:topic])
  end

  def get_by_id(id) do
    Endpoint
    |> Repo.get(id)
    |> Repo.preload(subscriptions: [:topic])
    |> Repo.preload(:consumer)
    |> Repo.preload(:project)
    |> case do
      nil -> {:error, :not_found}
      endpoint -> {:ok, endpoint}
    end
  end

  @doc """
  Creates a endpoint.

  ## Examples

      iex> create(%{field: value})
      {:ok, %Endpoint{}}

      iex> create(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create(attrs) do
    attrs = if is_struct(attrs), do: Map.from_struct(attrs), else: attrs

    if Map.has_key?(attrs, :subscribe) and not is_nil(attrs[:subscribe]) do
      with {:ok, topics} <- Topics.list_by_names(attrs.subscribe, attrs.project_id) do
        %Endpoint{}
        |> Endpoint.create_changeset(
          Enum.into(attrs, %{
            subscriptions:
              Enum.map(topics, fn %Topic{} = topic ->
                %{
                  topic_id: topic.id,
                  status: "enabled"
                }
              end)
          })
        )
        |> Repo.insert()
        |> Common.Ecto.preload(subscriptions: :topic)
      end
    else
      %Endpoint{}
      |> Endpoint.changeset(attrs)
      |> Repo.insert()
    end
  end

  @doc """
  Updates a endpoint.

  ## Examples

      iex> update(endpoint, %{field: new_value})
      {:ok, %Endpoint{}}

      iex> update(endpoint, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update(%Endpoint{} = endpoint, attrs) do
    endpoint
    |> Endpoint.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a endpoint.

  ## Examples

      iex> delete(endpoint)
      {:ok, %Endpoint{}}

      iex> delete(endpoint)
      {:error, %Ecto.Changeset{}}

  """
  def delete(%Endpoint{} = endpoint) do
    Repo.delete(endpoint)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking endpoint changes.

  ## Examples

      iex> change(endpoint)
      %Ecto.Changeset{data: %Endpoint{}}

  """
  def change(%Endpoint{} = endpoint, attrs \\ %{}) do
    Endpoint.changeset(endpoint, attrs)
  end

  def authorize(:get, %Scope{user: user}, _opts) do
    user.role in [:root, :admin, :support]
  end

  def authorize(:list, %Scope{user: user}, _opts) do
    user.role in [:root, :admin, :support]
  end

  def authorize(:create, %Scope{user: user}, _opts) do
    user.role in [:root, :admin]
  end

  def authorize(:update, %Scope{user: user}, _opts) do
    user.role in [:root, :admin]
  end

  def authorize(:delete, %Scope{user: user}, _opts) do
    user.role in [:root, :admin]
  end
end
