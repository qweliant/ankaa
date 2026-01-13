defmodule Ankaa.Emergency do
  @moduledoc """
  The context for handling emergency escalations.
  """
  alias Ankaa.Emergency.Incident
  alias Ankaa.Repo
  # Fetches the adapter defined in config (MockDispatcher)
  @adapter Application.compile_env(:ankaa, :emergency_adapter)


  @doc """
  Triggers an emergency medical services (EMS) dispatch for the given patient and alert.
  ## Parameters
    - patient: The patient struct requiring emergency assistance
    - alert: The alert struct that triggered the EMS call
  ## Returns
    - {:ok, dispatch_id} on success
    - {:error, reason} on failure
  """
  def trigger_ems(patient, alert) do
    # TODO: In the future, fetch the real address from the Patient record.
    # For now, it  missing.
    address = "1234 Mock Address (Patient Address Not Implemented)"

    payload = %{
      name: patient.name,
      address: address,
      # TODO: Add phone to User schema
      phone: "555-0100",
      reason: "Critical Vitals Alert: #{alert.type}",
      # "High Venous Pressure (280 mmHg)"
      vitals: alert.message,
      timestamp: DateTime.utc_now()
    }

    case @adapter.dispatch_help(payload) do
      {:ok, dispatch_id} ->
        create_incident_record(patient, alert, dispatch_id)
        {:ok, dispatch_id}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def cancel_ems(dispatch_id) do
    @adapter.cancel_dispatch(dispatch_id)
  end

  defp create_incident_record(patient, alert, dispatch_id) do
    %Incident{}
    |> Incident.changeset(%{
      patient_id: patient.id,
      alert_id: alert.id,
      trigger_time: DateTime.utc_now(),
      trigger_reason: alert.type,
      vital_snapshot: %{message: alert.message}, # In real life, grab the last 5 readings
      dispatch_id: dispatch_id,
      status: "dispatched"
    })
    |> Repo.insert!()
  end
end
