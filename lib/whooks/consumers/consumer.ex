defmodule Whooks.Consumers.Consumer do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :uid, :name, :metadata, :inserted_at, :updated_at]}

  @derive {
    Flop.Schema,
    filterable: [:uid, :name, :inserted_at, :updated_at],
    sortable: [:name, :inserted_at, :updated_at],
    default_order: %{
      order_by: [:name],
      order_directions: [:asc]
    }
  }

  @primary_key {:id, TypeID, autogenerate: true, prefix: "consumer", type: :string}
  @foreign_key_type TypeID
  schema "consumers" do
    field :uid, :string
    field :name, :string
    field :metadata, :map

    belongs_to :organization, Whooks.Organizations.Organization
    has_many :endpoints, Whooks.Endpoints.Endpoint

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(consumer, attrs) do
    consumer
    |> cast(attrs, [:uid, :name, :metadata, :organization_id])
    |> validate_required([:uid, :name])
    |> unique_constraint(:uid)
    |> foreign_key_constraint(:organization_id)
  end
end
