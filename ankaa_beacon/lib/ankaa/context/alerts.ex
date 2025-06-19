defmodule Ankaa.Alerts do
  @moduledoc """
  Handles alert logic and care network notifications.
  """

  alias Ankaa.Patients
  alias Ankaa.Patients.{PatientAssociation, Patient}
  alias Ankaa.Notifications

  import Ecto.Query
  alias Ankaa.Repo

  @doc """
  Broadcasts alerts to the patient's care network if thresholds are violated.
  """
  def broadcast_alerts(%{device_id: device_id} = reading, violations) do
    with %Patient{} = patient <- Patients.get_patient_by_device_id(device_id) do
      alert_recipients =
        PatientAssociation
        |> where([pa], pa.patient_id == ^patient.id and pa.can_alert == true)
        |> Repo.all()

      Enum.each(alert_recipients, fn assoc ->
        Notifications.send_alert_to_user(assoc.user_id, reading, violations)
      end)
    end
  end
end
