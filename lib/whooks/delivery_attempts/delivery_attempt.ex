defmodule Whooks.DeliveryAttempts.DeliveryAttempt do
  use Ecto.Schema
  use Flop.Schema

  import Ecto.Changeset

  @prefix "attempt"

  @flop_options [
    filterable: [:status, :inserted_at, :updated_at],
    sortable: [:status, :inserted_at, :updated_at],
    default_order: %{
      order_by: [:inserted_at],
      order_directions: [:desc]
    }
  ]

  @primary_key {:id, TypeID, autogenerate: true, prefix: @prefix, type: :string}
  @foreign_key_type TypeID
  schema "delivery_attempts" do
    field :status, Ecto.Enum,
      values: [
        :scheduled,
        :processing,
        :success,
        :retry,
        :failed,
        :discarded
      ],
      default: :scheduled

    field :ip, :string
    field :req_headers, :map
    field :res_headers, :map
    field :res_status, :integer
    field :res_body, :map
    field :latency_ms, :integer

    belongs_to :subscription, Whooks.Subscriptions.Subscription
    belongs_to :event, Whooks.Events.Event

    timestamps(type: :utc_datetime_usec)
  end

  def gen_id() do
    TypeID.new(@prefix)
  end

  @doc false
  def changeset(delivery_attempt, attrs) do
    delivery_attempt
    |> cast(attrs, [
      :status,
      :ip,
      :req_headers,
      :res_headers,
      :res_status,
      :res_body,
      :latency_ms,
      :subscription_id,
      :event_id
    ])
    |> validate_required([])
  end

  @doc false
  def create_changeset(delivery_attempt, attrs) do
    delivery_attempt
    |> cast(attrs, [
      :id,
      :status,
      :ip,
      :req_headers,
      :res_headers,
      :res_status,
      :res_body,
      :latency_ms,
      :subscription_id,
      :event_id
    ])
    |> validate_required([
      :subscription_id,
      :event_id
    ])
    |> foreign_key_constraint(:subscription_id)
    |> foreign_key_constraint(:event_id)
  end

  def update_changeset(delivery_attempt, attrs) do
    delivery_attempt
    |> cast(attrs, [
      :status,
      :ip,
      :req_headers,
      :res_headers,
      :res_status,
      :res_body,
      :latency_ms
    ])
    |> validate_required([:status])
  end
end
