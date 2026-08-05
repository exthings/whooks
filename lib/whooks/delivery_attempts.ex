defmodule Whooks.DeliveryAttempts do
  @moduledoc """
  The DeliveryAttempts context.
  """

  import Ecto.Query, warn: false
  alias Whooks.Repo

  alias Whooks.DeliveryAttempts.DeliveryAttempt

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
end
