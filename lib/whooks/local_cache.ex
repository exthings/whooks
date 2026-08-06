defmodule Whooks.LocalCache do
  use Nebulex.Cache,
    otp_app: :whooks,
    adapter: Nebulex.Adapters.Local
end
