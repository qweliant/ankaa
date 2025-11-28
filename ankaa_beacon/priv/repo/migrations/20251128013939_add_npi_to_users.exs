defmodule Ankaa.Repo.Migrations.AddNpiToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:npi_number, :string)
      add(:practice_state, :string)
    end

    create unique_index(:users, [:npi_number])
  end
end
