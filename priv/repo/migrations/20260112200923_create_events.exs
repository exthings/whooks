defmodule Whooks.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events, primary_key: false) do
      add :id, :string, size: 90, primary_key: true
      add :uid, :string
      add :status, :string
      add :data, :map
      add :tags, {:array, :string}
      add :metadata, :map

      add :topic_id,
          references(:topics, type: :string, on_delete: :nothing), size: 90

      add :project_id,
          references(:projects, type: :string, on_delete: :nothing), size: 90

      add :consumer_id,
          references(:consumers, type: :string, on_delete: :nothing), size: 90

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:events, [:uid])
    create index(:events, [:topic_id])
    create index(:events, [:project_id])
    create index(:events, [:consumer_id])
  end
end
