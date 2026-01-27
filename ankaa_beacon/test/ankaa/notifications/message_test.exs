defmodule Ankaa.MessagesTest do
  use Ankaa.DataCase, async: true

  alias Ankaa.Messages
  alias Ankaa.Notifications.Notification
  alias Ankaa.AccountsFixtures

  setup do
    patient_user = AccountsFixtures.patient_fixture()
    patient = patient_user.patient

    doctor = AccountsFixtures.doctor_fixture()

    {:ok, _assoc} =
      Ankaa.Patients.create_patient_association(doctor, patient, "Doctor", :admin, :doctor)

    %{patient: patient, doctor: doctor}
  end

  describe "passive check-ins" do
    test "send_passive_check_in/2 creates message, notification, and broadcasts", %{
      patient: patient,
      doctor: doctor
    } do
      Phoenix.PubSub.subscribe(Ankaa.PubSub, "patient:#{patient.id}:messages")

      {:ok, message} = Messages.send_passive_check_in(patient, doctor)

      assert message.content =~ "checking in"
      assert message.sender_id == doctor.id
      assert message.patient_id == patient.id
      assert message.read == false

      notification =
        Repo.get_by!(Notification, notifiable_id: message.id, notifiable_type: "Message")

      assert notification.user_id == patient.user_id
      assert notification.status == "unread"

      assert_receive {:new_message, ^message}
    end

    test "send_check_in_reply/3 creates a reply from patient", %{
      patient: patient,
      doctor: doctor
    } do
      {:ok, original} = Messages.send_passive_check_in(patient, doctor)

      # Subscribe to Caregiver's feed. they should receive the reply
      Phoenix.PubSub.subscribe(Ankaa.PubSub, "user:#{doctor.id}:messages")

      reply_content = "I'm doing great!"
      {:ok, reply} = Messages.send_check_in_reply(patient, original, reply_content)

      assert reply.content == reply_content
      # Patient is sender now
      assert reply.sender_id == patient.user_id
      # Still attached to patient chart
      assert reply.patient_id == patient.id

      notification =
        Repo.get_by!(Notification, notifiable_id: reply.id, notifiable_type: "Message")

      assert notification.user_id == doctor.id

      assert_receive {:new_message, ^reply}
    end
  end

  describe "conversations and inbox" do
    setup %{patient: patient, doctor: doctor} do
      nurse = AccountsFixtures.nurse_fixture()
      {:ok, _} = Ankaa.Patients.create_patient_association(nurse, patient, "Nurse", :contributor, :nurse)

      {:ok, msg1} = Messages.send_passive_check_in(patient, doctor)

      # Manually backdate this message by 1 minute so it is definitely "older"
      # This prevents the sorting race condition in tests.
      old_time =
        NaiveDateTime.utc_now()
        |> NaiveDateTime.add(-60, :second)
        |> NaiveDateTime.truncate(:second)

      msg1
      |> Ecto.Changeset.change(inserted_at: old_time)
      |> Ankaa.Repo.update!()

      {:ok, msg2} = Messages.send_passive_check_in(patient, nurse)
      {_count, _} = Messages.mark_messages_as_read(patient.id, nurse.id)

      %{doctor: doctor, nurse: nurse, msg1: msg1, msg2: msg2}
    end

    test "list_conversations_for_patient/1 groups messages by sender", %{
      patient: patient,
      doctor: doctor,
      nurse: nurse
    } do
      conversations = Messages.list_conversations_for_patient(patient.id)

      assert length(conversations) == 2

      # Find doctor conversation
      doc_convo = Enum.find(conversations, fn c -> c.sender.id == doctor.id end)
      assert doc_convo.unread_count == 1
      assert doc_convo.latest_message.content =~ "checking in"

      # Find nurse conversation
      nurse_convo = Enum.find(conversations, fn c -> c.sender.id == nurse.id end)
      # Marked as read in setup
      assert nurse_convo.unread_count == 0
    end

    test "get_unread_message_count/1 returns correct count", %{patient: patient} do
      assert Messages.get_unread_message_count(patient.id) == 1
    end

    test "get_messages_from_sender/2 returns thread history", %{patient: patient, doctor: doctor} do
      {:ok, msg2} = Messages.send_passive_check_in(patient, doctor)

      messages = Messages.get_messages_from_sender(patient.id, doctor.id)

      assert length(messages) == 2
      assert hd(messages).id == msg2.id
    end
  end

  describe "message status" do
    test "mark_messages_as_read/2 updates all messages from sender", %{
      patient: patient,
      doctor: doctor
    } do
      Messages.send_passive_check_in(patient, doctor)
      Messages.send_passive_check_in(patient, doctor)

      assert Messages.get_unread_message_count(patient.id) == 2

      {count, _} = Messages.mark_messages_as_read(patient.id, doctor.id)

      assert count == 2
      assert Messages.get_unread_message_count(patient.id) == 0
    end
  end

  describe "checked on alert" do
    test "send_checked_on_message/2 triggers SMS (mocked) and notification", %{
      patient: patient,
      doctor: doctor
    } do
      # We aren't mocking the actual HTTP SMS call here, but ensuring the Multi transaction succeeds
      # If you use a Mock library (Mox), you would verify the SMS call here.
      # For now, we verify the side effects in the DB.

      Phoenix.PubSub.subscribe(Ankaa.PubSub, "patient:#{patient.id}:messages")

      {:ok, message} = Messages.send_checked_on_message(patient, doctor)

      assert message.content =~ "checking on you"

      notification = Repo.get_by!(Notification, notifiable_id: message.id)
      assert notification.user_id == patient.user_id

      assert_receive {:new_message, ^message}
    end
  end
end
