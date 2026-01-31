defmodule Whooks.Repo.Migrations.CreateDeliveryAttempts do
  use Ecto.Migration

  def change do
    create table(:delivery_attempts, primary_key: false) do
      add :id, :string, size: 90, primary_key: true
      add :status, :string, size: 16
      add :ip, :string, size: 64
      add :res_status, :integer
      add :res_headers, :map
      add :res_body, :map
      add :latency_ms, :integer

      add :subscription_id, references(:subscriptions, type: :string, on_delete: :nothing),
        size: 90

      add :event_id, references(:events, type: :string, on_delete: :nothing), size: 90

      timestamps(type: :utc_datetime_usec)
    end

    create index(:delivery_attempts, [:event_id])
    create index(:delivery_attempts, [:subscription_id])
  end
end
