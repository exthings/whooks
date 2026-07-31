defmodule Whooks.RedisCache do
  use Nebulex.Cache,
    otp_app: :whooks,
    adapter: Nebulex.Adapters.Redis
end
