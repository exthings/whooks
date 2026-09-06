defmodule Whooks.Organizations.Organization do
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

  @primary_key {:id, TypeID, autogenerate: true, prefix: "org", type: :string}
  schema "organizations" do
    field :name, :string
    field :event_retention_days, :integer

    has_many :consumers, Whooks.Consumers.Consumer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :event_retention_days])
    |> validate_required([:name])
    |> validate_number(:event_retention_days, greater_than: 0)
  end
end
