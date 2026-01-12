import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :whooks, Whooks.Repo,
  username: System.get_env("DATABASE_USERNAME", "whooks"),
  password: System.get_env("DATABASE_PASSWORD", "whooks"),
  hostname: System.get_env("DATABASE_HOST", "localhost"),
  database: "whooks_test#{System.get_env("MIX_TEST_PARTITION")}",
  port: System.get_env("DATABASE_PORT", "5432") |> String.to_integer(),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :whooks, WhooksWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "OA1Ln+s6AGLOLv5zrCY2FDXj4QJ8WqlTdndH/oFB78mUn22jxhx47MlNNRC8l7ab",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
