defmodule Ankaa.Repo.Migrations.AddMessagesTable do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:sender_id, references(:users, type: :binary_id, on_delete: :delete_all))
      add(:patient_id, references(:users, type: :binary_id, on_delete: :delete_all))
      add(:content, :text)
      add(:read, :boolean, default: false)
      timestamps()
    end

    create(index(:messages, [:patient_id]))
  end
end
