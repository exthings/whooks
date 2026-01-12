defmodule Whooks.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration

  def change do
    create table(:organizations, primary_key: false) do
      add :id, :string, size: 90, primary_key: true
      add :name, :string, size: 64

      timestamps(type: :utc_datetime)
    end
  end
end
