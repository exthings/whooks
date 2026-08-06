defmodule Whooks.Topics do
  @moduledoc """
  The Topics context.
  """

  use Nebulex.Caching

  import Ecto.Query, warn: false
  alias Whooks.Repo
  alias Whooks.RedisCache

  alias Whooks.Topics.Topic

  @ttl :timer.minutes(10)

  @doc """
  Returns the list of topics.

  ## Examples

      iex> list()
      [%Topic{}, ...]

  """
  def list do
    Repo.all(Topic)
  end

  @doc """
  Gets a single topic.

  Raises `Ecto.NoResultsError` if the Topic does not exist.

  ## Examples

      iex> get!(123)
      %Topic{}

      iex> get!(456)
      ** (Ecto.NoResultsError)

  """
  @decorate cacheable(cache: RedisCache, opts: [ttl: @ttl])
  def get!(id), do: Repo.get!(Topic, id)

  @doc """
  Gets a single topic by name.

  Raises `Ecto.NoResultsError` if the Topic does not exist.

  ## Examples

      iex> get_by_name!("my-topic")
      %Topic{}

      iex> get_by_name!("non-existent")
      ** (Ecto.NoResultsError)

  """
  @decorate cacheable(cache: RedisCache, opts: [ttl: @ttl])
  def get_by_name!(name, project_id) do
    Repo.get_by!(Topic, name: name, project_id: project_id)
  end

  @decorate cacheable(cache: RedisCache, opts: [ttl: @ttl])
  def get_by_name!(name) do
    Repo.get_by!(Topic, name: name)
  end

  @doc """
  Returns the list of topics matching the given names.

  ## Examples

      iex> list_by_names(["topic-1", "topic-2"], project_id)
      [%Topic{}, ...]

  """
  def list_by_names(names, project_id) do
    unique_names = Enum.uniq(names)

    Topic
    |> where([t], t.name in ^unique_names)
    |> where([t], t.project_id == ^project_id)
    |> Repo.all()
    |> case do
      topics when topics != [] and length(topics) == length(unique_names) ->
        {:ok, topics}

      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Creates a topic.

  ## Examples

      iex> create(%{field: value})
      {:ok, %Topic{}}

      iex> create(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create(attrs) do
    %Topic{}
    |> Topic.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a topic.

  ## Examples

      iex> update(topic, %{field: new_value})
      {:ok, %Topic{}}

      iex> update(topic, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update(%Topic{} = topic, attrs) do
    topic
    |> Topic.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a topic.

  ## Examples

      iex> delete(topic)
      {:ok, %Topic{}}

      iex> delete(topic)
      {:error, %Ecto.Changeset{}}

  """
  def delete(%Topic{} = topic) do
    Repo.delete(topic)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking topic changes.

  ## Examples

      iex> change(topic)
      %Ecto.Changeset{data: %Topic{}}

  """
  def change(%Topic{} = topic, attrs \\ %{}) do
    Topic.changeset(topic, attrs)
  end
end
