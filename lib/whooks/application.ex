defmodule Whooks.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    bullmq_redis_url =
      Application.get_env(:whooks, :bullmq_redis_url, "redis://localhost:6379")

    children = [
      WhooksWeb.Telemetry,
      Whooks.Repo,
      # {Registry, keys: :duplicate, name: :redis_registry},
      # {Redix, name: :redis, host: "127.0.0.1", port: 6379},
      {BullMQ.RedisConnection, name: :bullmq_redis, url: bullmq_redis_url},
      {Whooks.RedisCache, []},
      {Whooks.LocalCache, []},
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
         concurrency: 200},
        id: :events_worker
      ),
      Supervisor.child_spec(
        {BullMQ.Worker,
         name: :delivery_worker,
         queue: "deliveries",
         connection: :bullmq_redis,
         processor: &WhooksWorker.DeliveryAttemptWorker.process/1,
         concurrency: 200},
        id: :delivery_worker
      ),
      Supervisor.child_spec(
        {BullMQ.Worker,
         name: :retention_worker,
         queue: "retention",
         connection: :bullmq_redis,
         processor: &WhooksWorker.RetentionWorker.process/1,
         concurrency: 5},
        id: :retention_worker
      )
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Whooks.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Whooks.Events.Retention.setup_scheduler()
        {:ok, pid}

      error ->
        error
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WhooksWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
