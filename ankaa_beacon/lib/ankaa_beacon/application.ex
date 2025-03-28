defmodule AnkaaBeacon.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AnkaaBeaconWeb.Telemetry,
      AnkaaBeacon.Repo,
      {DNSCluster, query: Application.get_env(:ankaa_beacon, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AnkaaBeacon.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: AnkaaBeacon.Finch},
      # Start a worker by calling: AnkaaBeacon.Worker.start_link(arg)
      # {AnkaaBeacon.Worker, arg},
      # Start to serve requests, typically the last entry
      AnkaaBeaconWeb.Endpoint,
      # Start Redis with config
      {AnkaaBeacon.Redis, Application.get_env(:ankaa, AnkaaBeacon.Redis, [])},
      # Start the mock data generator
      {AnkaaBeacon.MockData, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AnkaaBeacon.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AnkaaBeaconWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
