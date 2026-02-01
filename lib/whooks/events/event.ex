defmodule Whooks.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:uid, :status, :inserted_at, :updated_at],
    sortable: [:status, :inserted_at, :updated_at],
    default_order: %{
      order_by: [:inserted_at],
      order_directions: [:desc]
    }
  }

  @primary_key {:id, TypeID, autogenerate: true, prefix: "event", type: :string}
  @foreign_key_type TypeID
  schema "events" do
    field :uid, :string

    field :status, Ecto.Enum,
      values: [:pending, :scheduled, :processing, :retry, :success, :failed],
      default: :pending

    field :data, :map
    field :tags, {:array, :string}
    field :metadata, :map

    belongs_to :topic, Whooks.Topics.Topic
    belongs_to :project, Whooks.Projects.Project
    belongs_to :consumer, Whooks.Consumers.Consumer
    has_many :delivery_attempts, Whooks.DeliveryAttempts.DeliveryAttempt

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:uid, :data, :tags, :metadata, :consumer_id, :project_id, :topic_id, :status])
    |> validate_required([:uid, :data, :consumer_id, :project_id, :topic_id, :status])
    |> unique_constraint(:uid)
  end

  def create_changeset(event, attrs) do
    event
    |> cast(attrs, [:uid, :data, :tags, :metadata, :consumer_id, :project_id, :topic_id])
    |> validate_required([:uid, :data, :consumer_id, :project_id, :topic_id])
    |> unique_constraint(:uid)
    |> foreign_key_constraint(:consumer_id)
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:topic_id)
  end

  def update_changeset(event, attrs) do
    event
    |> cast(attrs, [:metadata, :status])
    |> validate_required([:status])
  end
end
