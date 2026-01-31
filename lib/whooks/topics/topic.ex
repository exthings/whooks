defmodule Whooks.Topics.Topic do
  use Ecto.Schema
  import Ecto.Changeset

  alias Whooks.Common

  @primary_key {:id, TypeID, autogenerate: true, prefix: "topic", type: :string}
  @foreign_key_type TypeID
  schema "topics" do
    field :name, :string
    field :status, :string
    field :description, :string
    field :json_schema, :map

    belongs_to :project, Whooks.Projects.Project
    has_many :subscriptions, Whooks.Subscriptions.Subscription
    has_many :events, Whooks.Events.Event

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(topic, attrs) do
    topic
    |> cast(attrs, [:name, :status, :description, :json_schema, :project_id])
    |> validate_required([:name, :status, :description, :json_schema, :project_id])
    |> unique_constraint([:name, :project_id])
    |> foreign_key_constraint(:project_id)
    |> Common.Changeset.validate_dot_notation(:name)
  end
end
