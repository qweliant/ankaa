defmodule Ankaa.Alerts do
  @moduledoc """
  Handles alert logic and care network notifications.
  """
  import Ecto.Query

  alias Ankaa.Patients
  alias Ankaa.Patients.CareNetwork
  alias Ankaa.Notifications.Alert
  alias Ankaa.Notifications.AlertTimer
  alias Ankaa.Repo

  require Logger

  def create_alert(attrs) do
    case %Alert{}
         |> Alert.changeset(attrs)
         |> Repo.insert() do
      {:ok, alert} ->
        if alert.severity == "critical" do
          AlertTimer.start_link(alert)
        end

        broadcast_alert_created(alert)
        {:ok, alert}

      error ->
        Logger.error("Failed to create alert: #{inspect(error)}")
        {:error, error}
    end
  end

  def broadcast_device_alerts(device_id, _reading, violations) do
    case Patients.get_patient_by_device_id(device_id) do
      %Patients.Patient{} = patient ->
        # Create alerts (which will auto-broadcast)
        Enum.each(violations, fn violation ->
          case create_alert(%{
                 type: "Monitoring alert",
                 message: violation.message,
                 patient_id: patient.id,
                 # Convert :critical -> "critical"
                 severity: Atom.to_string(violation.severity)
               }) do
            {:ok, _alert} ->
              :ok

            {:error, reason} ->
              Logger.error("Failed to create alert for patient #{patient.id}: #{inspect(reason)}")
          end
        end)

        :ok

      nil ->
        Logger.warning("No patient found for device_id: #{inspect(device_id)}")
        {:error, :patient_not_found}

      error ->
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
      from(a in Alert,
        where: a.patient_id in ^patient_ids and a.status == "active",
        order_by: [desc: a.inserted_at],
        preload: [:patient]
      )
      |> Repo.all()
    end
  end

  @doc """
  Dismisses an alert, creating an audit trail and broadcasting the change.
  """
  def dismiss_alert(%Alert{} = alert, %Ankaa.Accounts.User{} = user, dismissal_reason) do
    if can_dismiss_alert?(alert, user) do
      attrs = %{
        status: "dismissed",
        dismissed_at: DateTime.utc_now(),
        dismissed_by_user_id: user.id,
        dismissal_reason: dismissal_reason
      }

      case alert |> Alert.changeset(attrs) |> Repo.update() do
        {:ok, dismissed_alert} ->
          broadcast_alert_dismissed(dismissed_alert)
          {:ok, dismissed_alert}

        {:error, changeset} ->
          {:error, changeset}
      end
    else
      {:error, "You are not authorized to dismiss this alert."}
    end
  end

  @doc """
  Acknowledges a critical alert, creating an audit trail and stopping the EMS timer.
  """
  def acknowledge_critical_alert(%Alert{} = alert, user_id) do
    # 1. Cancel the countdown timer process
    AlertTimer.cancel(alert.id)

    # 2. Update the alert in the database
    attrs = %{
      acknowledged: true,
      dismissed_at: DateTime.utc_now(),
      dismissed_by_user_id: user_id,
      dismissal_reason: "critical_acknowledged"
    }

    case alert |> Alert.changeset(attrs) |> Repo.update() do
      {:ok, ack_alert} ->
        # 3. Broadcast that the alert was updated
        broadcast_alert_updated(ack_alert)
        {:ok, ack_alert}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp broadcast_alert_updated(alert) do
    care_network_user_ids = get_care_network_for_alerts(alert.patient_id)

    Enum.each(care_network_user_ids, fn user_id ->
      Phoenix.PubSub.broadcast(
        Ankaa.PubSub,
        "user:#{user_id}:alerts",
        {:alert_updated, alert}
      )
    end)
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
    IO.inspect({:broadcasting_dismissal_to, care_network_user_ids}, label: "PubSub")
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

  defp can_dismiss_alert?(alert, user) do
    case alert.severity do
      "info" -> true
      "high" -> true
      "critical" -> user.role in ["doctor", "nurse"]
    end
  end
end
