defmodule Ankaa.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      AnkaaWeb.Telemetry,
      # Start the Ecto repository
      Ankaa.Repo,
      # Start the TimescaleDB repository
      # Ankaa.TimescaleRepo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Ankaa.PubSub},
      # Start Finch
      {Finch, name: Ankaa.Finch},
      # Start the Endpoint (http/https)
      AnkaaWeb.Endpoint,
      # Start the Registry for alerts
      {Registry, keys: :unique, name: Ankaa.Notifications.AlertRegistry},
      # Start the Registry for
      {Registry, keys: :unique, name: Ankaa.Monitoring.DeviceRegistry}
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
