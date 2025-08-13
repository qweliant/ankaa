defmodule Ankaa.Repo.Migrations.AddScenarioToDevices do
  use Ecto.Migration

  def change do
    alter table(:devices) do
      add(:simulation_scenario, :string)
    end
  end
end
