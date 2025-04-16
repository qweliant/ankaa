defmodule Ankaa.Sessions.Session do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sessions" do
    field(:date, :date)
    field(:duration, :integer)
    field(:notes, :string)

    belongs_to(:patient, Ankaa.Patients.Patient)

    timestamps()
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:date, :duration, :notes, :patient_id])
    |> validate_required([:date, :duration, :patient_id])
    |> validate_number(:duration, greater_than: 0)
  end
end
