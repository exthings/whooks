defmodule Whooks.Metrics do
  import Ecto.Query, warn: false

  alias Whooks.Repo
  alias Whooks.Subscriptions.Subscription
  alias Whooks.Endpoints.Endpoint

  def count_subscriptions_by_project(project_id) do
    from(s in Subscription,
      join: e in Endpoint,
      on: e.id == s.endpoint_id,
      where: e.project_id == ^project_id,
      group_by: s.topic_id,
      select: %{topic_id: s.topic_id, count: count(s.id)}
    )
    |> Repo.all()
    |> case do
      [] ->
        {:ok, []}

      data ->
        {:ok, data}
    end
  end
end
