defmodule Ankaa.Monitoring.Threshold do
  @moduledoc """
  Schema and functions for patient-specific monitoring thresholds
  """
  use Ecto.Schema

  import Ecto.Query
  alias Ankaa.Repo

  schema "thresholds" do
    field(:device_type, Ecto.Enum, values: [:dialysis, :bp])
    field(:parameter, :string)
    field(:min_value, :float)
    field(:max_value, :float)
    field(:severity, Ecto.Enum, values: [:low, :medium, :high, :critical])

    belongs_to(:patient, Ankaa.Patients.Patient, foreign_key: :patient_id, type: :binary_id)
    timestamps()
  end

  @doc """
  Gets all thresholds for a specific patient and device type
  """
  def get_for_patient(%Ankaa.Patients.Patient{} = patient) do
    from(t in __MODULE__, where: t.patient_id == ^patient.id)
    |> Repo.all()
    |> Enum.group_by(& &1.parameter, &%{min: &1.min_value, max: &1.max_value})
    |> Enum.into(%{}, fn {param, [values | _]} -> {param, values} end)
  end
end
