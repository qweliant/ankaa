defmodule Ankaa.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Ankaa.Repo,
      Ankaa.TimescaleRepo,
      AnkaaWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:ankaa, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Ankaa.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Ankaa.Finch},
      # Start a worker by calling: Ankaa.Worker.start_link(arg)
      # {Ankaa.Worker, arg},
      # Start to serve requests, typically the last entry
      AnkaaWeb.Endpoint,
      # Start Redis with config
      {Ankaa.Redis, Application.get_env(:ankaa, Ankaa.Redis)},
      # Start MQTT Consumer
      Ankaa.Workers.MQTTConsumer
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
