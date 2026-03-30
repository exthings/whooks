defmodule Whooks.Repo.Migrations.AddReqHeadersColToDeliveryAttempts do
  use Ecto.Migration

  def change do
    alter table(:delivery_attempts) do
      add :req_headers, :map
    end
  end
end
