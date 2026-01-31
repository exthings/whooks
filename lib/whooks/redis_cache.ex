defmodule Whooks.RedisCache do
  use Nebulex.Cache,
    otp_app: :whooks,
    adapter: NebulexRedisAdapter
end
