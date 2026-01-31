defmodule Whooks.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WhooksWeb.Telemetry,
      Whooks.Repo,
      # {Registry, keys: :duplicate, name: :redis_registry},
      # {Redix, name: :redis, host: "127.0.0.1", port: 6379},
      {BullMQ.RedisConnection, name: :bullmq_redis, url: "redis://localhost:6379"},
      {Whooks.RedisCache, []},
      {DNSCluster, query: Application.get_env(:whooks, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Whooks.PubSub},

      # Start a worker by calling: Whooks.Worker.start_link(arg)
      # {Whooks.Worker, arg},
      # Start to serve requests, typically the last entry
      WhooksWeb.Endpoint,

      # BullMQ Workers
      Supervisor.child_spec(
        {BullMQ.Worker,
         name: :events_worker,
         queue: "events",
         connection: :bullmq_redis,
         processor: &WhooksWorker.EventsWorker.process/1,
         concurrency: 5},
        id: :events_worker
      ),
      Supervisor.child_spec(
        {BullMQ.Worker,
         name: :delivery_worker,
         queue: "deliveries",
         connection: :bullmq_redis,
         processor: &WhooksWorker.DeliveryAttemptWorker.process/1,
         concurrency: 5},
        id: :delivery_worker
      )
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Whooks.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WhooksWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
