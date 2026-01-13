defmodule Whooks.Organizations.Organization do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, TypeID, autogenerate: true, prefix: "org", type: :string}
  schema "organizations" do
    field :name, :string

    has_many :consumers, Whooks.Consumers.Consumer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
