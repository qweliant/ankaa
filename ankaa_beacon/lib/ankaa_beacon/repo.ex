defmodule AnkaaBeacon.Repo do
  use Ecto.Repo,
    otp_app: :ankaa_beacon,
    adapter: Ecto.Adapters.Postgres
end
