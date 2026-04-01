defmodule Whooks.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:name, :inserted_at, :updated_at],
    sortable: [:name, :inserted_at, :updated_at],
    default_order: %{
      order_by: [:name],
      order_directions: [:asc]
    }
  }
  @primary_key {:id, TypeID, autogenerate: true, prefix: "project", type: :string}
  @foreign_key_type TypeID
  schema "projects" do
    field :uid, :string
    field :status, Ecto.Enum, values: [:enabled, :disabled], default: :enabled
    field :name, :string
    field :metadata, :map

    belongs_to :organization, Whooks.Organizations.Organization
    has_many :topics, Whooks.Topics.Topic
    has_many :events, Whooks.Events.Event

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :metadata])
    |> validate_required([:name])
    |> foreign_key_constraint(:organization_id)
  end
end
