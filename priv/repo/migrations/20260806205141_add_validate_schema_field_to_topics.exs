defmodule Whooks.Repo.Migrations.AddValidateSchemaFieldToTopics do
  use Ecto.Migration

  def change do
    alter table(:topics) do
      add :validate_schema, :boolean, default: false
    end
  end
end
