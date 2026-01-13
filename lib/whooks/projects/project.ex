defmodule Whooks.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, TypeID, autogenerate: true, prefix: "project", type: :string}
  schema "projects" do
    field :name, :string
    field :metadata, :map
    field :organization_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :metadata])
    |> validate_required([:name])
  end
end
