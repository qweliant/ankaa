defmodule Ankaa.Alerts do
  @moduledoc """
  Handles alert logic and care network notifications.
  """

  alias Ankaa.Patients
  alias Ankaa.Patients.PatientAssociation
  alias Ankaa.Notifications
  alias Ankaa.Notifications.Alert

  import Ecto.Query
  alias Ankaa.Repo

  def create_alert(attrs) do
    %Alert{}
    |> Alert.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Broadcasts alerts to the patient's care network if thresholds are violated.
  """
  # def broadcast_alerts(%{device_id: device_id} = reading, violations) do
  #   with %Ankaa.Patients.Patient{} = patient <- Patients.get_patient_by_device_id(device_id) do
  #     # Persist alerts - CHANGED THIS LINE
  #     Enum.each(violations, fn violation ->
  #       create_alert(%{  # Changed from Notifications.create_alert to create_alert
  #         type: "threshold_violation",
  #         message: """
  #         ⚠️ Parameter: #{violation.parameter}
  #         Value: #{violation.value}
  #         Threshold: #{violation.threshold}
  #         Severity: #{violation.severity}
  #         Message: #{violation.message}
  #         """,
  #         patient_id: patient.id
  #       })
  #     end)

  #     # Broadcast to care network
  #     PatientAssociation
  #     |> where([pa], pa.patient_id == ^patient.id and pa.can_alert == true)
  #     |> Repo.all()
  #     |> Enum.each(fn assoc ->
  #       Notifications.send_alert_to_user(assoc.user_id, reading, violations)
  #     end)
  #   end
  # end
end
