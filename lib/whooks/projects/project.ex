defmodule Whooks.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, TypeID, autogenerate: true, prefix: "project", type: :string}
  @foreign_key_type TypeID
  schema "projects" do
    field :name, :string
    field :metadata, :map
    belongs_to :organization, Whooks.Organizations.Organization
    has_many :topics, Whooks.Topics.Topic

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
