defmodule Ankaa.Messages do
  @moduledoc """
  The Messages context.
  """
  alias Ankaa.Repo
  alias Postgrex.Message

  import Ecto.Query
  alias Ankaa.Notifications.Message
  alias Ankaa.Notifications.SMS
  alias Ankaa.Notifications
  alias Ankaa.Patients.Patient
  alias Ankaa.Accounts.User

  require Logger
  
  @doc "Lists all messages for a given patient."
  def list_messages_for_patient(patient_id) do
    from(m in Message,
      where: m.patient_id == ^patient_id,
      order_by: [desc: m.inserted_at]
    )
    |> Repo.all()
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

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:message, Message.changeset(%Message{}, attrs))
    |> Ecto.Multi.run(:notification, fn _repo, %{message: message} ->
      # Create a notification for the *patient* that points
      # to the new message.
      notification_attrs = %{
        # The patient's own user ID
        user_id: patient.user_id,
        notifiable_id: message.id,
        notifiable_type: "Message",
        status: "unread"
      }

      Notifications.create_notification(notification_attrs)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{message: message}} ->
        to_number = "+15551234567"
        sms_body = "Ankaa Alert: #{provider_name} is checking on #{patient.name}."
        SMS.send(to_number, sms_body)

        Phoenix.PubSub.broadcast(
          Ankaa.PubSub,
          "patient:#{patient.id}:messages",
          {:new_message, message}
        )

        {:ok, message}

      {:error, _failed_op, failed_value, _changes} ->
        {:error, failed_value}
    end
  end

  @doc """
  Creates a passive "check-in" message and a notification for the patient.
  """
  def send_passive_check_in(%Patient{} = patient, %User{} = caregiver) do
    provider_name =
      if caregiver.first_name,
        do: "#{caregiver.first_name} #{caregiver.last_name}",
        else: "Your Care Team"

    content = "#{provider_name} is checking in to see how you're doing!"

    attrs = %{
      content: content,
      sender_id: caregiver.id,
      patient_id: patient.id
    }

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:message, Message.changeset(%Message{}, attrs))
    |> Ecto.Multi.run(:notification, fn _repo, %{message: message} ->
        notification_attrs = %{
          user_id: patient.user_id,
          notifiable_id: message.id,
          notifiable_type: "Message",
          status: "unread"
        }
        # Use the function we created yesterday!
        Notifications.create_notification(notification_attrs)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{message: message, notification: _notification}} ->
        # Broadcast to the patient so they see it in real-time
        Phoenix.PubSub.broadcast(
          Ankaa.PubSub,
          "patient:#{patient.id}:messages",
          {:new_message, message}
        )
        {:ok, message}

      {:error, _failed_op, failed_value, _changes} ->
        Logger.error("Failed to create passive check-in: #{inspect(failed_value)}")
        {:error, failed_value}
    end
  end
end
