defmodule Ankaa.Notifications do
  @moduledoc """
  The Notifications context.
  """
  import Ecto.Query

  alias Postgrex.Messages
  alias Ankaa.Repo
  alias Ankaa.Notifications.Notification
  alias Ankaa.Notifications.Messages
  alias Ankaa.Notifications.SMS

  require Logger

  # get the configured SMS client from config/config.exs which would be a module that implements the SMS behaviour
  # @sms_client Application.compile_env(:ankaa, :sms_client)

  @doc """
  Finds a specific notification for a user and marks it as dismissed.
  """
  def dismiss_notification(user_id, alert_id) do
    from(n in Notification,
      where: n.user_id == ^user_id and n.alert_id == ^alert_id
    )
    |> Repo.update_all(set: [status: "dismissed"])
  end

  @doc """
  dismisses notifications for all users
  """
  def dismiss_all_notifications_for_alert(alert_id) do
    from(n in Notification,
      where: n.alert_id == ^alert_id
    )
    |> Repo.update_all(set: [status: "dismissed"])
  end

  @doc """
  Creates a "checked on" message for the patient's inbox and
  sends a (mock) SMS to their care support.
  """
  def send_checked_on_message(patient, care_network_member) do
    provider_name =
      if care_network_member.first_name,
        do: "#{care_network_member.first_name} #{care_network_member.last_name}",
        else: "Your Care Team"

    content =
      "#{provider_name} has seen your alert and is checking on you. Help is on the way."

    attrs = %{
      content: content,
      sender_id: care_network_member.id,
      patient_id: patient.id
    }

    with {:ok, message} <- %Messages{} |> Messages.changeset(attrs) |> Repo.insert() do
      to_number = "+15551234567"
      sms_body = "Ankaa Alert: #{provider_name} is checking on #{patient.name}."
      SMS.send(to_number, sms_body)

      Phoenix.PubSub.broadcast(
        Ankaa.PubSub,
        "patient:#{patient.id}:messages",
        {:new_message, message}
      )

      {:ok, message}
    end
  end
end
