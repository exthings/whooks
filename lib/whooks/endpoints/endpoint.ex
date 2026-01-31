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
    has_many :subscriptions, Whooks.Subscriptions.Subscription

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(endpoint, attrs) do
    endpoint
    |> cast(attrs, [
      :uid,
      :status,
      :url,
      :description,
      :headers,
      :metadata,
      :project_id,
      :consumer_id
    ])
    |> cast_assoc(:subscriptions)
    |> validate_required([:status, :url, :description, :project_id, :consumer_id])
    |> unique_constraint(:uid)
    |> foreign_key_constraint(:consumer_id)
    |> foreign_key_constraint(:project_id)
  end
end
