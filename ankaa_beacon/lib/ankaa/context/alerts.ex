defmodule Ankaa.Alerts do
  @moduledoc """
  Handles alert logic and care network notifications.
  """

  alias Ankaa.Patients
  alias Ankaa.Patients.CareNetwork
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
  def broadcast_alerts(device_id, reading, violations) do
    case Patients.get_patient_by_device_id(device_id) do
      %Ankaa.Patients.Patient{} = patient ->
        # Persist alerts
        Enum.each(violations, fn violation ->
          create_alert(%{
            type: "threshold_violation",
            message: """
            ⚠️ Parameter: #{violation.parameter}
            Value: #{violation.value}
            Threshold: #{violation.threshold}
            Severity: #{violation.severity}
            Message: #{violation.message}
            """,
            patient_id: patient.id
          })
        end)

        # Broadcast to care network
        CareNetwork
        |> where([pa], pa.patient_id == ^patient.id && pa.can_alert == true)
        |> Repo.all()
        |> Enum.each(fn assoc ->
          case Notifications.Alert.send_alert_to_user(assoc.user_id, reading, violations) do
            :ok ->
              :ok

            {:error, reason} ->
              require Logger

              Logger.error(
                "Failed to send alert to user #{inspect(assoc.user_id)}: #{inspect(reason)}"
              )
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
end
