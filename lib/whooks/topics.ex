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

      iex> list_topics()
      [%Topic{}, ...]

  """
  def list_topics do
    Repo.all(Topic)
  end

  @doc """
  Gets a single topic.

  Raises `Ecto.NoResultsError` if the Topic does not exist.

  ## Examples

      iex> get_topic!(123)
      %Topic{}

      iex> get_topic!(456)
      ** (Ecto.NoResultsError)

  """
  @decorate cacheable(cache: RedisCache, opts: [ttl: @ttl])
  def get_by_id!(id), do: Repo.get!(Topic, id)

  @doc """
  Gets a single topic by name.

  Raises `Ecto.NoResultsError` if the Topic does not exist.

  ## Examples

      iex> get_topic_by_name!("my-topic")
      %Topic{}

      iex> get_topic_by_name!("non-existent")
      ** (Ecto.NoResultsError)

  """
  @decorate cacheable(cache: RedisCache, opts: [ttl: @ttl])
  def get_by_name!(name, project_id) do
    Repo.get_by!(Topic, name: name, project_id: project_id)
  end

  @doc """
  Returns the list of topics matching the given names.

  ## Examples

      iex> list_topics_by_names(["topic-1", "topic-2"])
      [%Topic{}, ...]

  """
  def list_topics_by_names(names, project_id) do
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

      iex> create_topic(%{field: value})
      {:ok, %Topic{}}

      iex> create_topic(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_topic(attrs) do
    %Topic{}
    |> Topic.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a topic.

  ## Examples

      iex> update_topic(topic, %{field: new_value})
      {:ok, %Topic{}}

      iex> update_topic(topic, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_topic(%Topic{} = topic, attrs) do
    topic
    |> Topic.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a topic.

  ## Examples

      iex> delete_topic(topic)
      {:ok, %Topic{}}

      iex> delete_topic(topic)
      {:error, %Ecto.Changeset{}}

  """
  def delete_topic(%Topic{} = topic) do
    Repo.delete(topic)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking topic changes.

  ## Examples

      iex> change_topic(topic)
      %Ecto.Changeset{data: %Topic{}}

  """
  def change_topic(%Topic{} = topic, attrs \\ %{}) do
    Topic.changeset(topic, attrs)
  end
end
