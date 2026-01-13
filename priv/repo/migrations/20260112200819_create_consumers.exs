defmodule Whooks.Repo.Migrations.CreateConsumers do
  use Ecto.Migration

  def change do
    create table(:consumers, primary_key: false) do
      add :id, :string, size: 90, primary_key: true
      add :uid, :string, size: 90
      add :name, :string, size: 64
      add :metadata, :map

      add :organization_id,
          references(:organizations, type: :string, on_delete: :nothing), size: 90

      timestamps(type: :utc_datetime)
    end

    create unique_index(:consumers, [:uid])
    create index(:consumers, [:organization_id])
  end
end
