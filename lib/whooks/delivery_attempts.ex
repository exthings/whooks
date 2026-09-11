defmodule Whooks.DeliveryAttempts do
  @moduledoc """
  The DeliveryAttempts context.
  """

  import Ecto.Query, warn: false
  alias Whooks.Repo

  alias Whooks.DeliveryAttempts.DeliveryAttempt

  def get!(id), do: Repo.get!(DeliveryAttempt, id)

  def create_success(attrs) do
    %DeliveryAttempt{}
    |> DeliveryAttempt.create_changeset(Map.put(attrs, :status, :success))
    |> Repo.insert()
  end

  def create_failed(attrs) do
    %DeliveryAttempt{}
    |> DeliveryAttempt.create_changeset(Map.put(attrs, :status, :failed))
    |> Repo.insert()
  end

  def update_status(%DeliveryAttempt{} = attempt, status) do
    attempt
    |> DeliveryAttempt.update_changeset(%{status: status})
    |> Repo.update()
  end

  def update_to_processing(%DeliveryAttempt{} = attempt) do
    update_status(attempt, :processing)
  end

  def update_to_success(%DeliveryAttempt{} = attempt, attrs \\ %{}) do
    attempt
    |> DeliveryAttempt.update_changeset(Map.merge(attrs, %{status: :success}))
    |> Repo.update()
  end

  def update_to_retry(%DeliveryAttempt{} = attempt, attrs \\ %{}) do
    attempt
    |> DeliveryAttempt.update_changeset(Map.merge(attrs, %{status: :retry}))
    |> Repo.update()
  end

  def update_to_failed(%DeliveryAttempt{} = attempt, attrs \\ %{}) do
    attempt
    |> DeliveryAttempt.update_changeset(Map.merge(attrs, %{status: :failed}))
    |> Repo.update()
  end

  def update_to_discarded(%DeliveryAttempt{} = attempt, attrs \\ %{}) do
    attempt
    |> DeliveryAttempt.update_changeset(Map.merge(attrs, %{status: :discarded}))
    |> Repo.update()
  end
end
