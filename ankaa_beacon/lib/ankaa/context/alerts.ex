defmodule Ankaa.Alerts do
  @moduledoc """
  Handles alert logic and care network notifications.
  """
  import Ecto.Query

  alias Ankaa.Patients.CareNetwork
  alias Ankaa.Notifications.Alert
  alias Ankaa.Notifications.EMSAlertTimer
  alias Ankaa.Notifications.Notification
  alias Ankaa.Repo

  require Logger

  def create_alert(attrs) do
    patient_id = attrs["patient_id"] || attrs[:patient_id]
    care_network_user_ids = get_care_network_for_alerts(patient_id)

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:alert, Alert.changeset(%Alert{}, attrs))
      |> Ecto.Multi.run(:notifications, fn repo, %{alert: alert} ->
        # This step runs after the alert is successfully inserted.
        # We create a list of notification structs to be inserted all at once.
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        notifications =
          Enum.map(care_network_user_ids, fn user_id ->
            %{
              alert_id: alert.id,
              user_id: user_id,
              status: "unread",
              inserted_at: now,
              updated_at: now
            }
          end)

        case repo.insert_all(Notification, notifications) do
          {count, nil} ->
            {:ok, %{count: count}}

          other ->
            {:error, other}
        end
      end)

    case Repo.transaction(multi) do
      {:ok, %{alert: alert}} ->
        if alert.severity == "critical" do
          EMSAlertTimer.start_link(alert)
        end

        broadcast_alert_created(alert)
        {:ok, alert}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        Logger.error("Failed to create alert: #{inspect(failed_value)}")
        {:error, failed_value}
    end
  end

  def create_alerts_for_violations(%Ankaa.Patients.Patient{} = patient, violations) do
    Enum.each(violations, fn violation ->
      # We just create the alert. The create_alert function already
      # handles the broadcasting logic.
      create_alert(%{
        type: "Monitoring alert",
        message: violation.message,
        patient_id: patient.id,
        severity: Atom.to_string(violation.severity)
      })
    end)

    :ok
  end

  @doc """
  Gets all active alerts for a provider, excluding any they have dismissed.
  """
  def get_active_alerts_for_user(%Ankaa.Accounts.User{} = user) do
    # This query finds all alerts for a user WHERE a corresponding
    # notification for that user does NOT have a status of "dismissed".
    query =
      from(a in Alert,
        join: n in Notification,
        on: a.id == n.alert_id,
        join: p_assoc in CareNetwork,
        on: a.patient_id == p_assoc.patient_id,
        where: p_assoc.user_id == ^user.id and n.user_id == ^user.id,
        where: n.status in ["unread", "acknowledged"],
        order_by: [desc: a.inserted_at],
        preload: [:patient],
        select: %{alert: a, notification: n}
      )

    Repo.all(query)
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
    EMSAlertTimer.cancel(alert.id)

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
    from(cn in CareNetwork,
      # This checks if the `permissions` array contains the "receive_alerts" string
      where:
        cn.patient_id == ^patient_id and
          fragment("? @> ARRAY[?]::varchar[]", cn.permissions, "receive_alerts"),
      select: cn.user_id
    )
    |> Repo.all()
    end


    defp broadcast_alert_dismissed(alert) do
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

  defp can_dismiss_alert?(alert, user) do
    case alert.severity do
      "info" -> true
      "high" -> true
      "critical" -> user.role in ["doctor", "nurse"]
    end
  end
end
