defmodule Whooks.Consumers do
  @moduledoc """
  The Consumers context.
  """
  @behaviour Bodyguard.Policy

  import Ecto.Query, warn: false
  alias Whooks.Repo
  alias Whooks.Consumers.Consumer
  alias Whooks.Auth.Scope

  @doc """
  Returns the list of consumers.

  ## Examples

      iex> list()
      [%Consumer{}, ...]

  """
  def list do
    Repo.all(Consumer)
  end

  def list(params, opts \\ []) do
    Consumer
    |> apply_filters(opts)
    |> Flop.validate_and_run(params, for: Consumer)
  end

  def get_by_id(id) do
    Repo.get(Consumer, id)
    |> Repo.preload(:endpoints)
    |> case do
      nil -> {:error, :not_found}
      consumer -> {:ok, consumer}
    end
  end

  @doc """
  Gets a single consumer.

  Raises `Ecto.NoResultsError` if the Consumer does not exist.

  ## Examples

      iex> get!(123)
      %Consumer{}

      iex> get!(456)
      ** (Ecto.NoResultsError)

  """
  def get!(id), do: Repo.get!(Consumer, id)

  @doc """
  Creates a consumer.

  ## Examples

      iex> create(%{field: value})
      {:ok, %Consumer{}}

      iex> create(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create(attrs) do
    %Consumer{}
    |> Consumer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a consumer.

  ## Examples

      iex> update(consumer, %{field: new_value})
      {:ok, %Consumer{}}

      iex> update(consumer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update(%Consumer{} = consumer, attrs) do
    consumer
    |> Consumer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a consumer.

  ## Examples

      iex> delete(consumer)
      {:ok, %Consumer{}}

      iex> delete(consumer)
      {:error, %Ecto.Changeset{}}

  """
  def delete(%Consumer{} = consumer) do
    Repo.delete(consumer)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking consumer changes.

  ## Examples

      iex> change(consumer)
      %Ecto.Changeset{data: %Consumer{}}

  """
  def change(%Consumer{} = consumer, attrs \\ %{}) do
    Consumer.changeset(consumer, attrs)
  end

  defp apply_filters(q, opts) do
    Enum.reduce(opts, q, fn
      {:organization_id, id}, q -> where(q, [p], p.organization_id == ^id)
      _, q -> q
    end)
  end

  def authorize(:get, %Scope{user: user}, _opts) do
    user.role in [:root, :admin, :support]
  end

  def authorize(:list, %Scope{user: user}, _opts) do
    user.role in [:root, :admin, :support]
  end

  def authorize(:create, %Scope{user: user}, _opts) do
    user.role == :root
  end

  def authorize(:create_portal_link, %Scope{user: user}, _opts) do
    user.role in [:root, :admin, :support]
  end

  def authorize(:update, %Scope{user: user}, _opts) do
    user.role == :root
  end

  def authorize(:delete, %Scope{user: user}, _opts) do
    user.role == :root
  end
end
