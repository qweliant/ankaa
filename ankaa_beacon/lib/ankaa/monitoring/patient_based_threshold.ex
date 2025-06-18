defmodule Ankaa.Monitoring.Threshold do
  @moduledoc """
  Schema and functions for patient-specific monitoring thresholds
  """
  use Ecto.Schema

  schema "thresholds" do
    field(:device_type, Ecto.Enum, values: [:dialysis, :bp])
    field(:parameter, :string)
    field(:min_value, :float)
    field(:max_value, :float)
    field(:severity, Ecto.Enum, values: [:low, :medium, :high, :critical])

    belongs_to(:patient, Ankaa.Accounts.User)

    timestamps()
  end

  # Changeset and query functions

  @doc """
  Gets all thresholds for a specific patient and device type
  """
  @spec get_for_patient(User.t(), atom()) :: [Threshold.t()]
  def get_for_patient(_patient, _device_type) do
    # Query thresholds for this patient and device type
  end

  
end
