defmodule Ankaa.Notifications.EscalationPolicy do
  @moduledoc """
  Manages escalation policies for unacknowledged alerts.
  """

  alias Ankaa.Notifications.{Alert, Recipient}
  alias Ankaa.Accounts.User

  @type escalation_level :: 0..3
  @type escalation_result :: {:ok, Alert.t()} | {:error, term()}

  @doc """
  Gets the escalation policy for a patient.
  """
  @spec get_policy(User.t()) :: {:ok, map()} | {:error, term()}
  def get_policy(patient) do
    case patient do
      %{id: _} ->
        {:ok,
         %{
           max_level: 3,
           # minutes between escalations
           timeouts: [15, 30, 60],
           roles: [:caresupport, :doctor, :emergency_contact]
         }}

      _ ->
        {:error, :invalid_patient}
    end
  end

  @doc """
  Determines the next escalation level and recipients.
  """
  @spec get_next_escalation(Alert.t()) ::
          {:ok, {escalation_level(), [Recipient.t()]}} | {:error, term()}
  def get_next_escalation(alert) do
    with {:ok, policy} <- get_policy(alert.patient),
         {:ok, next_level} <- calculate_next_level(alert, policy),
         {:ok, recipients} <- get_recipients_for_level(alert.patient, next_level, policy) do
      {:ok, {next_level, recipients}}
    end
  end

  @doc """
  Schedules the next escalation for an alert.
  """
  @spec schedule_escalation(Alert.t()) :: escalation_result()
  def schedule_escalation(alert) do
    with {:ok, policy} <- get_policy(alert.patient),
         {:ok, next_level} <- calculate_next_level(alert, policy),
         timeout <- Enum.at(policy.timeouts, next_level - 1),
         next_time <- DateTime.add(DateTime.utc_now(), timeout * 60, :second) do
      alert
      |> Alert.changeset(%{
        escalation_level: next_level,
        next_escalation_at: next_time
      })

      # |> Ankaa.Repo.update() # this would update the escalation level and next escalation time in the database
    end
  end

  # Private functions

  defp calculate_next_level(alert, policy) do
    next_level = alert.escalation_level + 1

    if next_level <= policy.max_level do
      {:ok, next_level}
    else
      {:error, :max_escalation_reached}
    end
  end

  defp get_recipients_for_level(patient, level, policy) do
    role = Enum.at(policy.roles, level - 1)

    case role do
      nil -> {:error, :no_recipients_for_level}
      _ -> Recipient.get_recipients_by_role(patient, role)
    end
  end
end
