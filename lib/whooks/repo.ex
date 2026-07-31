defmodule Whooks.Repo do
  use Ecto.Repo,
    otp_app: :whooks,
    adapter: Ecto.Adapters.MyXQL
end
