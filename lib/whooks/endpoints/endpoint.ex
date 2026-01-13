defmodule Whooks.Endpoints.Endpoint do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, TypeID, autogenerate: true, prefix: "endpoint", type: :string}
  @foreign_key_type TypeID
  schema "endpoints" do
    field :uid, :string
    field :status, :string
    field :url, :string
    field :description, :string
    field :headers, :map
    field :metadata, :map
    field :secret, :string
    field :old_secrets, :map

    belongs_to :consumer, Whooks.Consumers.Consumer
    belongs_to :project, Whooks.Projects.Project

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(endpoint, attrs) do
    endpoint
    |> cast(attrs, [:uid, :status, :url, :description, :headers, :metadata])
    |> validate_required([:status, :url, :description])
    |> unique_constraint(:uid)
    |> foreign_key_constraint(:consumer_id)
    |> foreign_key_constraint(:project_id)
  end
end
