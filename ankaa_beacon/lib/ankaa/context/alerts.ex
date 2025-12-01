defmodule Ankaa.Alerts do
  @moduledoc """
  Handles alert logic and care network notifications.
  """
  import Ecto.Query
  alias Ankaa.Repo

  alias Ankaa.Patients.CareNetwork
  alias Ankaa.Notifications.Alert
  alias Ankaa.Emergency.EMSAlertTimer
  alias Ankaa.Notifications.Notification
  alias Ankaa.Patients
  alias Ankaa.Accounts

  require Logger

  def create_alert(attrs) do
    patient_id = attrs["patient_id"] || attrs[:patient_id]
    care_network_user_ids = get_care_network_for_alerts(patient_id)
    patient_user_id = Patients.get_patient!(patient_id).user_id

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:alert, Alert.changeset(%Alert{}, attrs))
      |> Ecto.Multi.run(:notifications, fn repo, %{alert: alert} ->
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        notifications =
          Enum.map(care_network_user_ids, fn user_id ->
            %{
              notifiable_id: alert.id,
              notifiable_type: "Alert",
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
        if alert.severity in ["high", "critical"] do
          if alert.severity == "critical" do
            EMSAlertTimer.start_link(alert)
          end

          Phoenix.PubSub.broadcast(
            Ankaa.PubSub,
            "patient_alerts:#{patient_user_id}:alerts",
            {:new_alert, alert}
          )


        end

        broadcast_alert_created(alert)
        {:ok, alert}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        Logger.error("Failed to create alert: #{inspect(failed_value)}")
        {:error, failed_value}
    end
  end

  @doc """
  Creates alerts for a patient based on a list of violations.
  Each violation should be a map with at least :message and :severity keys.

  Example:

      iex> violations = [%{message: "High heart rate", severity: :high}]
      iex> Ankaa.Alerts.create_alerts_for_violations(patient, violations)
      :ok
  """
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
  - For providers, it gets alerts for all their associated patients.
  - For patients, it gets alerts for themselves.
  """
def get_active_alerts_for_user(%Ankaa.Accounts.User{} = user) do
    cond do
      # --- PROVIDER LOGIC (Stays the same) ---
      user.role in ["doctor", "nurse", "caresupport", "clinic_technician", "social_worker"] ->
        query =
          from(n in Notification,
            where: n.user_id == ^user.id,
            where: n.status in ["unread", "acknowledged"],
            join: a in Alert,
            on: n.notifiable_id == a.id and n.notifiable_type == "Alert",
            where: a.status == "active",
            join: p in assoc(a, :patient),
            order_by: [desc: a.inserted_at],
            select: {n, a, p}
          )
        results = Repo.all(query)
        Enum.map(results, fn {notification, alert, patient} ->
          alert_with_patient = %{alert | patient: patient}
          %{alert: alert_with_patient, notification: notification}
        end)

      # --- PATIENT LOGIC (FIXED) ---
      Accounts.User.patient?(user) ->
        query =
          from(a in Alert,
            # 1. Start with ALERTS (The source of truth)
            join: p in assoc(a, :patient),

            # 2. Optional Join: Look for a notification for this user
            left_join: n in Notification,
            on: n.notifiable_id == a.id and n.notifiable_type == "Alert" and n.user_id == ^user.id,

            # 3. Alert Filters
            where: a.patient_id == ^user.patient.id,
            where: a.status == "active",
            where: a.severity in ["high", "critical"],

            # 4. Notification Filter:
            # Show if (No Notification Exists) OR (Notification exists AND is not dismissed)
            where: is_nil(n.id) or n.status != "dismissed",

            order_by: [desc: a.inserted_at],
            # Select all 3, even if 'n' is nil
            select: {n, a, p}
          )

        results = Repo.all(query)

        # Fix the tuple match to handle 3 items
        Enum.map(results, fn {notification, alert, patient} ->
          alert_with_patient = %{alert | patient: patient}
          # Pass the notification (which might be nil, and that's okay!)
          %{alert: alert_with_patient, notification: notification}
        end)

      true ->
        []
    end
  end

  @doc """
  Dismisses an alert, creating an audit trail and broadcasting the change.

  Example:

      iex> Ankaa.Alerts.dismiss_alert(alert, user, "No longer relevant")
      {:ok, %Alert{}}
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
    EMSAlertTimer.cancel(alert.id)

    attrs = %{
      acknowledged: true,
      dismissed_at: DateTime.utc_now(),
      dismissed_by_user_id: user_id,
      dismissal_reason: "critical_acknowledged",
      status: "acknowledged"
    }

    case alert |> Alert.changeset(attrs) |> Repo.update() do
      {:ok, ack_alert} ->
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
    care_network_user_ids = get_care_network_for_alerts(alert.patient_id)

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

    Enum.each(care_network_user_ids, fn user_id ->
      Phoenix.PubSub.broadcast(
        Ankaa.PubSub,
        "user:#{user_id}:alerts",
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
