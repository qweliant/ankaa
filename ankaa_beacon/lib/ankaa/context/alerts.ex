defmodule Ankaa.Alerts do
  @moduledoc """
  Handles alert logic and care network notifications.
  """

  alias ElixirSense.Log
  alias Ankaa.Patients
  alias Ankaa.Patients.CareNetwork
  alias Ankaa.Notifications
  alias Ankaa.Notifications.Alert

  import Ecto.Query
  alias Ankaa.Repo

  def create_alert(attrs) do
    case %Alert{}
         |> Alert.changeset(attrs)
         |> Repo.insert() do
      {:ok, alert} ->
        broadcast_alert_created(alert)
        {:ok, alert}

      error ->
        Log.error("Failed to create alert: #{inspect(error)}")
        {:error, error}
    end
  end

  def broadcast_device_alerts(device_id, reading, violations) do
    case Patients.get_patient_by_device_id(device_id) do
      %Patients.Patient{} = patient ->
        # Create alerts (which will auto-broadcast)
        Enum.each(violations, fn violation ->
          case create_alert(%{
                 type: "Monitoring alert",
                 # Use the nice formatted message from ThresholdViolation
                 message: violation.message,
                 patient_id: patient.id,
                 # Convert :critical -> "critical"
                 severity: Atom.to_string(violation.severity)
               }) do
            {:ok, _alert} ->
              :ok

            {:error, reason} ->
              require Logger
              Logger.error("Failed to create alert for patient #{patient.id}: #{inspect(reason)}")
          end
        end)

        :ok

      nil ->
        require Logger
        Logger.warn("No patient found for device_id: #{inspect(device_id)}")
        {:error, :patient_not_found}

      error ->
        require Logger

        Logger.error(
          "Error fetching patient by device_id #{inspect(device_id)}: #{inspect(error)}"
        )

        {:error, :unexpected_error}
    end
  end

  defp broadcast_alert_created(alert) do
    # Get all care network members who can receive alerts
    care_network = get_care_network_for_alerts(alert.patient_id)

    # Broadcast to each care network member
    Enum.each(care_network, fn user_id ->
      Phoenix.PubSub.broadcast(
        Ankaa.PubSub,
        "user:#{user_id}:alerts",
        {:new_alert, alert}
      )
    end)
  end

  defp get_care_network_for_alerts(patient_id) do
    CareNetwork
    |> where([pa], pa.patient_id == ^patient_id and pa.can_alert == true)
    |> select([pa], pa.user_id)
    |> Repo.all()
  end

  def get_active_alerts_for_user(user) do
    # Query for active alerts based on user role and relationships
    # This integrates with your existing alert/patient relationships
  end

  def dismiss_alert(alert_id, user_id, dismissal_reason) do
    # Handle alert dismissal with audit trail
    # Different logic based on alert severity
  end

  def acknowledge_critical_alert(alert_id, user_id) do
    # Stop EMS timer and mark as acknowledged
    # Full audit trail for critical alerts
  end
end
