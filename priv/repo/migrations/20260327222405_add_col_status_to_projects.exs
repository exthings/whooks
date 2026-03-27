defmodule Whooks.Repo.Migrations.AddColStatusToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :status, :string, default: "enabled"
    end
  end
end
