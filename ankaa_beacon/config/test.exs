# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :ankaa, Ankaa.Repo,
  username: "user",
  password: "password",
  hostname: "localhost",
  database: "ankaa_dev",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# Configure TimescaleDB
config :ankaa, Ankaa.TimescaleRepo,
  username: "user",
  password: "password",
  hostname: "localhost",
  database: "ankaa_timescale_dev",
  port: 5433,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# Configure Redis for testing
config :ankaa, Ankaa.Redis,
  host: "localhost",
  port: 6379,
  database: 1,
  pool_size: 5,
  pool_max_overflow: 2,
  enable_notifications: false

# Configure MQTT for testing
config :ankaa, :mqtt,
  host: "localhost",
  port: 1883,
  client_id: "ankaa_test",
  username: nil,
  password: nil,
  clean_session: true,
  keep_alive: 60,
  reconnect_timeout: 5_000

# Configure your application
config :ankaa, :ecto_repos, [Ankaa.Repo, Ankaa.TimescaleRepo]

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ankaa, AnkaaWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "2DSYlBvRJSaKYaLlTWHJOfGwM9k6XRptE/X4gza1TmLFFpvuvZnWSiFM/Oj8SMZ3",
  server: false

# In test we don't send emails
config :ankaa, Ankaa.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
