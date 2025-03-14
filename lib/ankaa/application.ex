defmodule Ankaa.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AnkaaWeb.Telemetry,
      # Ankaa.Repo,
      {DNSCluster, query: Application.get_env(:ankaa, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Ankaa.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Ankaa.Finch},
      # Start a worker by calling: Ankaa.Worker.start_link(arg)
      # {Ankaa.Worker, arg},
      # Start to serve requests, typically the last entry
      AnkaaWeb.Endpoint,
      {Ankaa.Redis, Application.get_env(:ankaa, Ankaa.Redis)}, # Start Redis with config
      Ankaa.MockData  # Start the mock data generator
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ankaa.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AnkaaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
