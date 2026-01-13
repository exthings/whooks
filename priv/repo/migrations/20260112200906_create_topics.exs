defmodule Whooks.Repo.Migrations.CreateTopics do
  use Ecto.Migration

  def change do
    create table(:topics, primary_key: false) do
      add :id, :string, size: 90, primary_key: true
      add :name, :string, size: 64
      add :status, :string
      add :description, :string
      add :json_schema, :map
      add :project_id, references(:projects, type: :string, on_delete: :nothing), size: 90

      timestamps(type: :utc_datetime)
    end

    create unique_index(:topics, [:name, :project_id])
    create index(:topics, [:project_id])
  end
end
