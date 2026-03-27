defmodule Whooks.Repo.Migrations.AddColExampleToTopics do
  use Ecto.Migration

  def change do
    alter table(:topics) do
      add :example, :map
    end
  end
end
