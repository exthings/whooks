defmodule Whooks.Repo.Migrations.CreateEndpoints do
  use Ecto.Migration

  def change do
    create table(:endpoints, primary_key: false) do
      add :id, :string, size: 90, primary_key: true
      add :uid, :string, size: 90
      add :status, :string
      add :url, :string
      add :description, :string
      add :headers, :map
      add :metadata, :map
      add :secret, :string
      add :old_secrets, :map
      add :consumer_id, references(:consumers, type: :string, on_delete: :nothing), size: 90
      add :project_id, references(:projects, type: :string, on_delete: :nothing), size: 90

      timestamps(type: :utc_datetime)
    end

    create unique_index(:endpoints, [:uid])
    create index(:endpoints, [:consumer_id])
    create index(:endpoints, [:project_id])
  end
end
