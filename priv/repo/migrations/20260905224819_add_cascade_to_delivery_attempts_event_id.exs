defmodule Whooks.Repo.Migrations.AddCascadeToDeliveryAttemptsEventId do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE delivery_attempts DROP FOREIGN KEY delivery_attempts_event_id_fkey"

    alter table(:delivery_attempts) do
      modify :event_id, references(:events, type: :string, on_delete: :delete_all), size: 90
    end
  end

  def down do
    execute "ALTER TABLE delivery_attempts DROP FOREIGN KEY delivery_attempts_event_id_fkey"

    alter table(:delivery_attempts) do
      modify :event_id, references(:events, type: :string, on_delete: :nothing), size: 90
    end
  end
end
