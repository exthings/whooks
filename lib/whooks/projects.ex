defmodule Whooks.Projects do
  @moduledoc """
  The Projects context.
  """
  @behaviour Bodyguard.Policy

  import Ecto.Query, warn: false
  alias Whooks.Repo

  alias Whooks.Projects.Project
  alias Whooks.Organizations.Organization
  alias Whooks.Auth.Scope

  @doc """
  Returns the list of projects.

  ## Examples

      iex> list()
      [%Project{}, ...]

  """
  def list do
    Repo.all(Project)
  end

  def list(params, opts \\ []) do
    from(p in Project,
      join: o in Organization,
      on: p.organization_id == o.id,
      preload: [:organization]
    )
    |> apply_filters(opts)
    |> Flop.validate_and_run(params, for: Project)
  end

  @doc """
  Gets a single project.

  Raises `Ecto.NoResultsError` if the Project does not exist.

  ## Examples

      iex> get!(123)
      %Project{}

      iex> get!(456)
      ** (Ecto.NoResultsError)

  """
  def get!(id), do: Repo.get!(Project, id)

  def get_by_id(id) do
    Project
    |> Repo.get(id)
    |> Repo.preload(:organization)
    |> Repo.preload(:topics)
    |> case do
      nil -> {:error, :not_found}
      project -> {:ok, project}
    end
  end

  @doc """
  Creates a project.

  ## Examples

      iex> create(%{field: value})
      {:ok, %Project{}}

      iex> create(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create(attrs) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a project.

  ## Examples

      iex> update(project, %{field: new_value})
      {:ok, %Project{}}

      iex> update(project, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a project.

  ## Examples

      iex> delete(project)
      {:ok, %Project{}}

      iex> delete(project)
      {:error, %Ecto.Changeset{}}

  """
  def delete(%Project{} = project) do
    Repo.delete(project)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking project changes.

  ## Examples

      iex> change(project)
      %Ecto.Changeset{data: %Project{}}

  """
  def change(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
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

  def authorize(:update, %Scope{user: user}, _opts) do
    user.role == :root
  end

  def authorize(:delete, %Scope{user: user}, _opts) do
    user.role == :root
  end
end
