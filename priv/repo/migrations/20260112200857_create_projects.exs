defmodule Whooks.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects, primary_key: false) do
      add :id, :string, size: 90, primary_key: true
      add :uid, :string, size: 64
      add :name, :string, size: 64
      add :metadata, :map

      add :organization_id,
          references(:organizations, type: :string, on_delete: :nothing), size: 90

      timestamps(type: :utc_datetime)
    end

    create index(:projects, [:organization_id])
  end
end
