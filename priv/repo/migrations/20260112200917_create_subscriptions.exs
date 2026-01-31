defmodule Whooks.Repo.Migrations.CreateSubscriptions do
  use Ecto.Migration

  def change do
    create table(:subscriptions, primary_key: false) do
      add :id, :string, size: 90, primary_key: true
      add :status, :string
      add :endpoint_id, references(:endpoints, type: :string, on_delete: :nothing), size: 90
      add :topic_id, references(:topics, type: :string, on_delete: :nothing), size: 90

      timestamps(type: :utc_datetime)
    end

    create index(:subscriptions, [:endpoint_id])
    create index(:subscriptions, [:topic_id])
  end
end
