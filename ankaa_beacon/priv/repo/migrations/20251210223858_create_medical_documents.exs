defmodule Ankaa.Repo.Migrations.CreateMedicalDocuments do
  use Ecto.Migration

  def change do
    create table(:medical_documents, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :file_url, :string, null: false
      add :file_type, :string
      add :category, :string

      add :patient_id, references(:patients, on_delete: :delete_all, type: :binary_id), null: false
      add :uploaded_by_id, references(:users, on_delete: :nilify_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:medical_documents, [:patient_id])
  end
end
