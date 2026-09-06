defmodule Whooks.Repo.Migrations.AddEventRetentionDaysToOrganizations do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :event_retention_days, :integer, default: nil
    end
  end
end
