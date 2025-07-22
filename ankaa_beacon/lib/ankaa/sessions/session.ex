defmodule Ankaa.Sessions.Session do
  @moduledoc """
  Tracks info about patient sessions
  """
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ["ongoing", "completed", "aborted"]

  schema "sessions" do
    field(:start_time, :utc_datetime)
    field(:end_time, :utc_datetime)
    field(:status, :string, default: "ongoing")

    field(:notes, :string)

    belongs_to(:patient, Ankaa.Patients.Patient, foreign_key: :patient_id, type: :binary_id)

    timestamps()
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:start_time, :end_time, :status, :notes, :patient_id])
    |> validate_required([:start_time, :status, :patient_id])
    |> validate_inclusion(:status, @statuses)
  end
end
