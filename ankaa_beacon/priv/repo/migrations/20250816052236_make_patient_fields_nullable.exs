defmodule Ankaa.Repo.Migrations.MakePatientFieldsNullable do
  use Ecto.Migration

  def change do
    alter table(:patients) do
      modify(:date_of_birth, :date, null: true)
      modify(:timezone, :string, null: true)
    end
  end
end
