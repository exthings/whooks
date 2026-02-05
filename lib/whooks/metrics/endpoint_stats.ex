defmodule Whooks.Metrics.EndpointStats do
  import Ecto.Query, warn: false
  import Timescale.Hyperfunctions

  alias Whooks.Repo

  alias Whooks.Events.Event
  alias Whooks.DeliveryAttempts.DeliveryAttempt
  alias Whooks.Subscriptions.Subscription
  alias Whooks.Metrics.Utils

  def timeseries(opts \\ []) do
    last = Keyword.get(opts, :last, "24h")

    from(e in Event,
      group_by: [selected_as(:date_time), e.status],
      order_by: [asc: selected_as(:date_time)],
      join: da in DeliveryAttempt,
      on: da.event_id == e.id,
      join: s in Subscription,
      on: s.id == da.subscription_id,
      select: %{
        date_time:
          selected_as(
            time_bucket_gapfill(e.inserted_at, ^Utils.interval_to_duration(last)),
            :date_time
          ),
        status: e.status,
        count: fragment("coalesce(count(*), 0)")
      }
    )
    |> apply_filters(opts)
    |> Repo.all()
    |> case do
      [] ->
        {:ok, []}

      events ->
        {:ok, events}
    end
  end

  defp apply_filters(q, opts) do
    Enum.reduce(opts, q, fn
      {:consumer_id, consumer_id}, q ->
        where(q, [e, da, s], e.consumer_id == ^consumer_id)

      {:project_id, project_id}, q ->
        where(q, [e, da, s], e.project_id == ^project_id)

      {:endpoint_id, endpoint_id}, q ->
        where(q, [e, da, s], s.endpoint_id == ^endpoint_id)

      {:last, last}, q ->
        where(
          q,
          [e, da, s],
          e.inserted_at >= ^Utils.parse_last_to_date_time(last) and
            e.inserted_at <= fragment("now()")
        )

      _, q ->
        q
    end)
  end
end
