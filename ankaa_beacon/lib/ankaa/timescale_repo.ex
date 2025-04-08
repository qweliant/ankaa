defmodule Ankaa.TimescaleRepo do
  use Ecto.Repo,
    otp_app: :ankaa,
    adapter: Ecto.Adapters.Postgres
end
