defmodule Ankaa.Monitoring do
  alias Ankaa.Repo
  alias Ankaa.Monitoring.Reading

  @doc """
  Creates a new reading record for the historical log.
  """
  def save_reading(%Ankaa.Patients.Device{} = device, reading_data_struct) do
    attrs = %{
      patient_id: device.patient_id,
      device_id: device.id, # The unique UUID of the device record
      payload: Map.from_struct(reading_data_struct), # Store the full reading as a map
      recorded_at: reading_data_struct.timestamp
    }

    %Reading{}
    |> Reading.changeset(attrs)
    |> Repo.insert()
  end
end
