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

  @doc """
  Returns a changeset for the message form.
  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  @doc """
  Creates a generic message between two users and broadcasts it.
  """
  def create_message(attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, message} ->
        # Preload sender/recipient for the UI
        message = Repo.preload(message, [:sender, :recipient])
        broadcast_message(message)
        {:ok, message}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

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
      recipient_id: patient.user_id,
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

      Notifications.create_notification(notification_attrs)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{message: message}} ->
        to_number = "+15551234567"
        sms_body = "Ankaa Alert: #{provider_name} is checking on #{patient.name}."
        SMS.send(to_number, sms_body)

        broadcast_message(message)

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
      patient_id: patient.id,
      recipient_id: patient.user_id
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

      Notifications.create_notification(notification_attrs)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{message: message, notification: _notification}} ->
        message = Repo.preload(message, [:sender, :recipient])
        broadcast_message(message)

        {:ok, message}

      {:error, _failed_op, failed_value, _changes} ->
        Logger.error("Failed to create passive check-in: #{inspect(failed_value)}")
        {:error, failed_value}
    end
  end

  @doc """
  Creates a reply to a passive "check-in" message.
  """
  def send_check_in_reply(%Patient{} = patient, %Message{} = original_message, content) do
    attrs = %{
      content: content,
      sender_id: patient.user_id,
      patient_id: patient.id,
      recipient_id: original_message.sender_id
    }

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:message, Message.changeset(%Message{}, attrs))
    |> Ecto.Multi.run(:notification, fn _repo, %{message: message} ->
      notification_attrs = %{
        user_id: original_message.sender_id,
        notifiable_id: message.id,
        notifiable_type: "Message",
        status: "unread"
      }

      Notifications.create_notification(notification_attrs)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{message: message, notification: _notification}} ->
        message = Repo.preload(message, [:sender, :recipient])
        broadcast_message(message)

        {:ok, message}

      {:error, _failed_op, failed_value, _changes} ->
        Logger.error("Failed to create check-in reply: #{inspect(failed_value)}")
        {:error, failed_value}
    end
  end

  @doc """
  Lists all messages for a patient, grouped by sender.

  Returns a list of maps, each containing:
  * `:sender` - The preloaded %User{} struct of the sender.
  * `:latest_message` - The most recent %Message{} struct in the thread.
  * `:unread_count` - The count of unread messages from that sender.
  """
  def list_conversations_for_patient(patient_id) do
    query =
      from(m in Message,
        where: m.patient_id == ^patient_id,
        preload: [:sender],
        order_by: [desc: m.inserted_at]
      )

    conversations =
      Repo.all(query)
      |> Enum.group_by(& &1.sender_id)
      |> Enum.map(fn {_sender_id, messages} ->
        latest_message = hd(messages)
        unread_count = Enum.count(messages, &(&1.read == false))

        %{
          sender: latest_message.sender,
          latest_message: latest_message,
          unread_count: unread_count
        }
      end)
      |> Enum.sort_by(& &1.latest_message.inserted_at, {:desc, NaiveDateTime})

    conversations
  end

  @doc """
  Finds all conversations for a specific User (not just patient).
  It finds anyone this user has sent messages to OR received messages from.
  """
  def list_conversations_for_user(user_id) do
    query =
      from m in Message,
        where: m.sender_id == ^user_id or m.recipient_id == ^user_id,
        preload: [:sender, :recipient],
        order_by: [desc: m.inserted_at]

    Repo.all(query)
    |> Enum.group_by(fn message ->
      if message.sender_id == user_id, do: message.recipient_id, else: message.sender_id
    end)
    |> Enum.map(fn {_partner_id, messages} ->
      latest = hd(messages)
      partner = if latest.sender_id == user_id, do: latest.recipient, else: latest.sender

      unread_count =
        Enum.count(messages, fn m ->
          m.recipient_id == user_id and m.read == false
        end)

      %{
        partner: partner,
        latest_message: latest,
        unread_count: unread_count
      }
    end)
    |> Enum.sort_by(& &1.latest_message.inserted_at, {:desc, NaiveDateTime})
  end

  @doc """
  Gets the total unread message count for a patient.
  """
  def get_unread_message_count(patient_id) do
    query =
      from(m in Message,
        where: m.patient_id == ^patient_id and m.read == false,
        select: count(m.id)
      )

    Repo.one(query)
  end

  @doc """
  Gets all messages for a patient from a specific sender.
  """
  def get_messages_from_sender(patient_id, sender_id) do
    from(m in Message,
      where: m.patient_id == ^patient_id and m.sender_id == ^sender_id,
      order_by: [desc: m.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets the chat history between two specific users.
  """
  def get_messages_between(user_a_id, user_b_id) do
    from(m in Message,
      where:
        (m.sender_id == ^user_a_id and m.recipient_id == ^user_b_id) or
          (m.sender_id == ^user_b_id and m.recipient_id == ^user_a_id),
      order_by: [desc: m.inserted_at],
      preload: [:sender, :recipient]
    )
    |> Repo.all()
  end

  @doc """
  Marks all unread messages from a sender as read.
  """
  def mark_messages_as_read(patient_id, sender_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    from(m in Message,
      where:
        m.patient_id == ^patient_id and
          m.sender_id == ^sender_id and
          m.read == false,
      update: [set: [read: true, updated_at: ^now]]
    )
    |> Repo.update_all([])
  end

  defp broadcast_message(message) do
    if message.recipient_id do
      Phoenix.PubSub.broadcast(
        Ankaa.PubSub,
        "user:#{message.recipient_id}:messages",
        {:new_message, message}
      )
    end

    if message.sender_id do
      Phoenix.PubSub.broadcast(
        Ankaa.PubSub,
        "user:#{message.sender_id}:messages",
        {:new_message, message}
      )
    end

    if message.patient_id do
      Phoenix.PubSub.broadcast(
        Ankaa.PubSub,
        "user:#{message.patient_id}:messages",
        {:new_message, message}
      )
    end
  end
end
