defmodule Ankaa.Medical.Document do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "medical_documents" do
    field :name, :string
    field :file_url, :string
    field :file_type, :string
    field :category, :string

    belongs_to :patient, Ankaa.Patients.Patient
    belongs_to :uploaded_by, Ankaa.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(document, attrs) do
    document
    |> cast(attrs, [:name, :file_url, :file_type, :category, :patient_id, :uploaded_by_id])
    |> validate_required([:name, :file_url, :patient_id])
  end
end
