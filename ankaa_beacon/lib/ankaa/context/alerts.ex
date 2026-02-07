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
  Gets a single alert. Raises Ecto.NoResultsError if the Alert does not exist.
  """
  def get_alert!(id), do: Repo.get!(Alert, id)

  @doc """
  Gets all active alerts for a provider, excluding any they have dismissed.
  - For providers, it gets alerts for all their associated patients.
  - For patients, it gets alerts for themselves.
  """
  def get_active_alerts_for_user(%Ankaa.Accounts.User{} = user) do
    # What is in my Inbox?
    # Any user (Doctor, Nurse, Mom, etc.) who received a notification sees it here.
    inbox_alerts = list_inbox_alerts(user)

    # What is happening to me?
    # If this user corresponds to a Patient record, fetch their direct feed.
    # (We assume get_patient_by_user_id/1 is efficient or user.patient is preloaded)
    feed_alerts =
      case Ankaa.Patients.get_patient_by_user_id(user.id) do
        %Ankaa.Patients.Patient{} = patient ->
          list_patient_feed_alerts(user, patient)

        nil ->
          []
      end

    # Combine and Deduplicate
    # (Just in case a user is both a Patient AND has a Notification for the same alert)
    (inbox_alerts ++ feed_alerts)
    |> Enum.uniq_by(fn item -> item.alert.id end)
  end

  @doc """
  Dismisses an alert, creating an audit trail and broadcasting the change.

  Example:

      iex> Ankaa.Alerts.dismiss_alert(alert, user, "No longer relevant")
      {:ok, %Alert{}}
  """
  def dismiss_alert(alert_id, %Ankaa.Accounts.User{} = user, dismissal_reason) do
    alert = Repo.get!(Alert, alert_id)

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

  def can_dismiss_alert?(alert, user) do
    if alert.severity in ["info", "low", "medium"] do
      true
    else
      check_clinical_permission(user, alert.patient_id)
    end
  end

  defp check_clinical_permission(user, patient_id) do
    query =
      from cn in CareNetwork,
      where: cn.user_id == ^user.id and cn.patient_id == ^patient_id,
      where: cn.role in [:doctor, :nurse, :tech]

    Repo.exists?(query)
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
      where: cn.patient_id == ^patient_id,
      # where: cn.role in [:owner, :admin, :contributor],
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

  defp list_inbox_alerts(user) do
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

    Repo.all(query)
    |> format_results()
  end

  defp list_patient_feed_alerts(user, patient) do
    query =
      from(a in Alert,
        # Scope: Alerts belonging to this patient
        where: a.patient_id == ^patient.id,
        where: a.status == "active",

        # Scope: Only High/Critical shown directly to patients
        where: a.severity in ["high", "critical"],

        # Optimization: Join Notification just to check dismissal status
        left_join: n in Notification,
        on:
          n.notifiable_id == a.id and
            n.notifiable_type == "Alert" and
            n.user_id == ^user.id,

        # Filter: Exclude if the user explicitly dismissed it via a notification
        where: is_nil(n.id) or n.status != "dismissed",
        join: p in assoc(a, :patient),
        order_by: [desc: a.inserted_at],
        # n might be nil here
        select: {n, a, p}
      )

    Repo.all(query)
    |> format_results()
  end

  defp format_results(results) do
    Enum.map(results, fn {notification, alert, patient} ->
      alert_with_patient = %{alert | patient: patient}
      # Notification might be nil (for Patient Feed items)
      %{alert: alert_with_patient, notification: notification}
    end)
  end
end
