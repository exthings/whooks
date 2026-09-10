defmodule Whooks.Projects.Project do
  use Ecto.Schema
  use Flop.Schema

  import Ecto.Changeset
  import Ecto.Query

  require Logger

  @flop_options [
    filterable: [:name, :inserted_at, :updated_at],
    sortable: [:name, :inserted_at, :updated_at],
    default_order: %{
      order_by: [:name],
      order_directions: [:asc]
    },
    custom_fields: [
      name: [
        filter: {Whooks.Filters, :ilike, []},
        field_dynamic: {Whooks.Filters, :name_field, []},
        ecto_type: :string,
        operators: [:ilike]
      ]
    ]
  ]

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
    |> cast(attrs, [:uid, :status, :name, :metadata, :organization_id])
    |> validate_required([:name, :organization_id])
    |> foreign_key_constraint(:organization_id)
  end
end
