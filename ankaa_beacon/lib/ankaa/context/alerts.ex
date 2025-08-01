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
    case %Alert{}
         |> Alert.changeset(attrs)
         |> Repo.insert() do
      {:ok, alert} ->
        broadcast_alert_created(alert)
        {:ok, alert}

      error ->
        Logger.error("Failed to create alert: #{inspect(error)}")
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

  @doc """
  Gets all active alerts for the patients associated with a given provider.
  """
  def get_active_alerts_for_user(%Ankaa.Accounts.User{} = user) do
    patients = Patients.list_patients_for_any_role(user)
    patient_ids = Enum.map(patients, & &1.id)

    if patient_ids == [] do
      []
    else
      from(a in Alert, where: a.patient_id in ^patient_ids, order_by: [desc: a.inserted_at])
      |> Repo.all()
    end
  end

  @doc """
  Dismisses an alert, creating an audit trail and broadcasting the change.
  """
  def dismiss_alert(alert_id, user_id, dismissal_reason) do
    case Repo.get(Alert, alert_id) do
      nil ->
        {:error, :not_found}

      alert ->
        attrs = %{
          status: "dismissed",
          dismissed_at: DateTime.utc_now(),
          dismissed_by_user_id: user_id,
          dismissal_reason: dismissal_reason
        }

        case alert |> Alert.changeset(attrs) |> Repo.update() do
          {:ok, dismissed_alert} ->
            broadcast_alert_dismissed(dismissed_alert)
            {:ok, dismissed_alert}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  def acknowledge_critical_alert(alert_id, user_id) do
    # Stop EMS timer and mark as acknowledged
    # Full audit trail for critical alerts
  end

  defp broadcast_alert_created(alert) do
    # Get all care network members who can receive alerts
    care_network_user_ids = get_care_network_for_alerts(alert.patient_id)

    # Broadcast to each care network member
    Enum.each(care_network_user_ids, fn user_id ->
      Phoenix.PubSub.broadcast(
        Ankaa.PubSub,
        "user:#{user_id}:alerts",
        {:new_alert, alert}
      )
    end)
  end

  defp get_care_network_for_alerts(patient_id) do
    CareNetwork
    |> where([cn], cn.patient_id == ^patient_id and cn.can_alert == true)
    |> select([cn], cn.user_id)
    |> Repo.all()
  end

  defp broadcast_alert_dismissed(alert) do
    # Get all care network members
    care_network_user_ids = get_care_network_for_alerts(alert.patient_id)

    # Broadcast the dismissal to each member
    Enum.each(care_network_user_ids, fn user_id ->
      Phoenix.PubSub.broadcast(
        Ankaa.PubSub,
        "user:#{user_id}:alerts",
        # The AlertHook is already set up to handle this message
        {:alert_dismissed, alert.id}
      )
    end)
  end
end
