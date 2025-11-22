defmodule Ankaa.Patients.MoodTracker do
  @moduledoc """
  Schema for tracking patient moods, symptoms, and notes.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Ankaa.Patients.Patient
  @mood_options ["Good", "Okay", "Fatigued", "Great", "Poor"]
  @available_symptoms ["Cramps", "Itchy", "Nausea", "Headache", "Fever", "Felt Cold", "Shortness of Breath"]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "mood_trackers" do
    field(:mood, :string, default: "Okay")
    field(:symptoms, {:array, :string}, default: [])
    field(:notes, :string)

    belongs_to :patient, Patient, foreign_key: :patient_id, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(mood_tracker, attrs) do
    mood_tracker
    |> cast(attrs, [:mood, :symptoms, :notes, :patient_id])
    |> validate_required([:mood, :patient_id])
    |> validate_inclusion(:mood, @mood_options)
    |> validate_subset(:symptoms, @available_symptoms)
  end
end
