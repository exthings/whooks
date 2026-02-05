defmodule Whooks.Metrics.Endpoints do
  import Ecto.Query, warn: false
  import Timescale.Hyperfunctions

  alias Whooks.Repo

  alias Whooks.Events.Event
  alias Whooks.DeliveryAttempts.DeliveryAttempt
  alias Whooks.Subscriptions.Subscription

  alias Whooks.TimeParser

  def deliveries(opts \\ []) do
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
            time_bucket_gapfill(e.inserted_at, ^interval_to_duration(last)),
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
          e.inserted_at >= ^TimeParser.parse_last_to_date_time(last) and
            e.inserted_at <= fragment("now()")
        )

      _, q ->
        q
    end)
  end

  defp interval_to_duration(last) do
    case last do
      "1m" -> Duration.new!(second: 1)
      "1h" -> Duration.new!(minute: 1)
      "6h" -> Duration.new!(minute: 10)
      "12h" -> Duration.new!(minute: 30)
      "24h" -> Duration.new!(minute: 30)
      "48h" -> Duration.new!(minute: 30)
      "1d" -> Duration.new!(hour: 1)
      "1w" -> Duration.new!(hour: 1)
      "1mo" -> Duration.new!(day: 1)
      "1y" -> Duration.new!(month: 1)
      _ -> Duration.new!(hour: 1)
    end
  end
end
