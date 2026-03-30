defmodule Whooks.DeliveryAttempts.DeliveryAttempt do
  use Ecto.Schema
  import Ecto.Changeset

  @prefix "attempt"

  @primary_key {:id, TypeID, autogenerate: true, prefix: @prefix, type: :string}
  @foreign_key_type TypeID
  schema "delivery_attempts" do
    field :status, Ecto.Enum, values: [:success, :failed]
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
      :status,
      :req_headers,
      :res_status,
      :res_headers,
      :latency_ms,
      :subscription_id,
      :event_id
    ])
    |> foreign_key_constraint(:subscription_id)
    |> foreign_key_constraint(:event_id)
  end
end
