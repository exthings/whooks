defmodule Whooks.Endpoints do
  @moduledoc """
  The Endpoints context.
  """
  @behaviour Bodyguard.Policy

  import Ecto.Query, warn: false

  use Nebulex.Caching

  alias Whooks.Repo

  alias Whooks.Endpoints.Endpoint
  alias Whooks.Topics
  alias Whooks.Topics.Topic
  alias Whooks.Common
  alias Whooks.Consumers.Consumer
  alias Whooks.Endpoints.Endpoint
  alias Whooks.Subscriptions.Subscription
  alias Whooks.Auth
  alias Whooks.Auth.Scope
  alias Whooks.RedisCache

  @ttl :timer.minutes(60)

  @doc """
  Returns the list of endpoints.

  ## Examples

      iex> list()
      [%Endpoint{}, ...]

  """
  def list(%Scope{} = scope, params \\ %{}) do
    from(e in Endpoint,
      join: c in assoc(e, :consumer),
      as: :consumer
    )
    |> Auth.scope_query(scope)
    |> Flop.validate_and_run(params, for: Endpoint)
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

  # @decorate cache_put(cache: RedisCache, opts: [ttl: @ttl])
  def get(%Scope{} = scope, id, opts \\ []) do
    from(e in Endpoint,
      join: c in assoc(e, :consumer),
      as: :consumer,
      where: e.id == ^id,
      preload: [:project, :consumer, subscriptions: [:topic]]
    )
    |> Auth.scope_query(scope)
    |> apply_filters(opts)
    |> Repo.one()
    |> case do
      nil ->
        {:error, :not_found}

      endpoint ->
        {:ok, endpoint}
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

  defp apply_filters(q, opts) do
    Enum.reduce(opts, q, fn
      {:consumer_id, consumer_id}, q ->
        where(q, [e], e.consumer_id == ^consumer_id)

      {:project_id, project_id}, q ->
        where(q, [e], e.project_id == ^project_id)
    end)
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
