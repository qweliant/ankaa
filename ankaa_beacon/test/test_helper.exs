ExUnit.start()

# Configure Ecto for support and tests
Application.put_env(:ecto, :primary_key_type, :id)

#  supervisors, including Ankaa.Repo.
Application.ensure_all_started(:ankaa)

# Start Ecto repositories
Ecto.Adapters.SQL.Sandbox.mode(Ankaa.Repo, :manual)

# Start the application
{:ok, _} = Application.ensure_all_started(:ex_machina)
