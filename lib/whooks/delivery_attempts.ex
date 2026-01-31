defmodule Whooks.DeliveryAttempts do
  @moduledoc """
  The DeliveryAttempts context.
  """

  import Ecto.Query, warn: false
  alias Whooks.Repo

  alias Whooks.DeliveryAttempts.DeliveryAttempt

  @doc """
  Returns the list of delivery_attempts.

  ## Examples

      iex> list_delivery_attempts()
      [%DeliveryAttempt{}, ...]

  """
  def list_delivery_attempts do
    Repo.all(DeliveryAttempt)
  end

  @doc """
  Gets a single delivery_attempt.

  Raises `Ecto.NoResultsError` if the Delivery attempt does not exist.

  ## Examples

      iex> get_delivery_attempt!(123)
      %DeliveryAttempt{}

      iex> get_delivery_attempt!(456)
      ** (Ecto.NoResultsError)

  """
  def get_delivery_attempt!(id), do: Repo.get!(DeliveryAttempt, id)

  def create_success(attrs) do
    %DeliveryAttempt{}
    |> DeliveryAttempt.create_changeset(Map.put(attrs, :status, "success"))
    |> Repo.insert()
  end

  def create_failed(attrs) do
    %DeliveryAttempt{}
    |> DeliveryAttempt.create_changeset(Map.put(attrs, :status, "failed"))
    |> Repo.insert()
  end

  @doc """
  Updates a delivery_attempt.

  ## Examples

      iex> update_delivery_attempt(delivery_attempt, %{field: new_value})
      {:ok, %DeliveryAttempt{}}

      iex> update_delivery_attempt(delivery_attempt, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_delivery_attempt(%DeliveryAttempt{} = delivery_attempt, attrs) do
    delivery_attempt
    |> DeliveryAttempt.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a delivery_attempt.

  ## Examples

      iex> delete_delivery_attempt(delivery_attempt)
      {:ok, %DeliveryAttempt{}}

      iex> delete_delivery_attempt(delivery_attempt)
      {:error, %Ecto.Changeset{}}

  """
  def delete_delivery_attempt(%DeliveryAttempt{} = delivery_attempt) do
    Repo.delete(delivery_attempt)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking delivery_attempt changes.

  ## Examples

      iex> change_delivery_attempt(delivery_attempt)
      %Ecto.Changeset{data: %DeliveryAttempt{}}

  """
  def change_delivery_attempt(%DeliveryAttempt{} = delivery_attempt, attrs \\ %{}) do
    DeliveryAttempt.changeset(delivery_attempt, attrs)
  end
end
