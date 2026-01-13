defmodule Whooks.Consumers.Consumer do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, TypeID, autogenerate: true, prefix: "consumer", type: :string}
  @foreign_key_type TypeID
  schema "consumers" do
    field :uid, :string
    field :name, :string
    field :metadata, :map

    belongs_to :organization, Whooks.Organizations.Organization

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(consumer, attrs) do
    consumer
    |> cast(attrs, [:uid, :name, :metadata])
    |> validate_required([:uid, :name])
    |> unique_constraint(:uid)
    |> foreign_key_constraint(:organization_id)
  end
end
