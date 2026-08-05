defmodule Whooks.Organizations do
  @moduledoc """
  The Organizations context.
  """
  @behaviour Bodyguard.Policy

  import Ecto.Query, warn: false
  alias Whooks.Repo
  alias Whooks.Auth.Scope
  alias Whooks.Organizations.Organization

  require Logger

  @doc """
  Returns the list of organizations.

  ## Examples

      iex> list()
      [%Organization{}, ...]

  """
  def list do
    Repo.all(Organization)
  end

  def list(params) do
    Organization
    |> Flop.validate_and_run(params, for: Organization)
  end

  @doc """
  Gets a single organization.

  Raises `Ecto.NoResultsError` if the Organization does not exist.

  ## Examples

      iex> get!(123)
      %Organization{}

      iex> get!(456)
      ** (Ecto.NoResultsError)

  """
  def get!(id), do: Repo.get!(Organization, id)

  @doc """
  Creates a organization.

  ## Examples

      iex> create(%{field: value})
      {:ok, %Organization{}}

      iex> create(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create(attrs) do
    %Organization{}
    |> Organization.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a organization.

  ## Examples

      iex> update(organization, %{field: new_value})
      {:ok, %Organization{}}

      iex> update(organization, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update(%Organization{} = organization, attrs) do
    organization
    |> Organization.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a organization.

  ## Examples

      iex> delete(organization)
      {:ok, %Organization{}}

      iex> delete(organization)
      {:error, %Ecto.Changeset{}}

  """
  def delete(%Organization{} = organization) do
    Repo.delete(organization)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking organization changes.

  ## Examples

      iex> change(organization)
      %Ecto.Changeset{data: %Organization{}}

  """
  def change(%Organization{} = organization, attrs \\ %{}) do
    Organization.changeset(organization, attrs)
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
