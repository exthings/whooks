defmodule Whooks.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :string, size: 90, primary_key: true
      add :external_id, :string, size: 64
      add :name, :string, size: 255
      add :email, :string, null: false, size: 255
      add :role, :string, null: true, size: 32
      add :hashed_password, :string, size: 512
      add :confirmed_at, :utc_datetime
      add :disabled_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:external_id])

    create table(:access_tokens, primary_key: false) do
      add :id, :string, size: 90, primary_key: true
      add :entity_id, :string, size: 90
      add :entity_type, :string, size: 90
      add :token, :binary, null: false, size: 64
      add :context, :string, null: false, size: 64
      add :sent_to, :string, size: 255
      add :authenticated_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:access_tokens, [:entity_id])
    create unique_index(:access_tokens, [:context, :token])
  end
end
