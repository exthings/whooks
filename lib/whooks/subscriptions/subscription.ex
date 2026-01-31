defmodule Whooks.Subscriptions.Subscription do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, TypeID, autogenerate: true, prefix: "sub", type: :string}
  @foreign_key_type TypeID
  schema "subscriptions" do
    field :status, :string

    belongs_to :endpoint, Whooks.Endpoints.Endpoint
    belongs_to :topic, Whooks.Topics.Topic
    has_many :delivery_attempts, Whooks.DeliveryAttempts.DeliveryAttempt

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [:status, :endpoint_id, :topic_id])
    |> validate_required([:status, :topic_id])
    |> assoc_constraint(:endpoint)
    |> assoc_constraint(:topic)
  end
end
