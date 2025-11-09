defmodule Ankaa.InvitesTest do
  use Ankaa.DataCase, async: true

  alias Ankaa.Invites
  alias Ankaa.Notifications.Invite
  alias Ankaa.Patients.{CareNetwork, Patient}
  alias Ankaa.AccountsFixtures

  setup do
    # The central patient for whom care is being coordinated.
    patient_user = AccountsFixtures.patient_fixture()

    # Care providers who can send and receive invites.
    doctor_user = AccountsFixtures.doctor_fixture()
    nurse_user = AccountsFixtures.nurse_fixture()

    # A brand new user who will be invited to become a patient.
    new_user_to_be_patient = AccountsFixtures.user_fixture(%{email: "new.patient@example.com"})

    %{
      patient_user: patient_user,
      patient_record: patient_user.patient,
      doctor_user: doctor_user,
      nurse_user: nurse_user,
      new_user_to_be_patient: new_user_to_be_patient
    }
  end

  describe "create_invite/2" do
    test "a doctor can create an invite for a patient", %{
      doctor_user: doctor_user,
      new_user_to_be_patient: new_user_to_be_patient
    } do
      attrs = %{
        "invitee_email" => new_user_to_be_patient.email,
        "invitee_role" => "patient"
        # patient_id is nil because the invite is not for an existing patient
      }

      assert {:ok, %Invite{invitee_role: "patient"}} =
               Invites.create_invite(doctor_user, attrs)
    end

    test "a patient can create an invite for a nurse", %{
      patient_user: patient_user,
      nurse_user: nurse_user
    } do
      attrs = %{
        "invitee_email" => nurse_user.email,
        "invitee_role" => "nurse",
        "patient_id" => patient_user.patient.id
      }

      assert {:ok, %Invite{invitee_role: "nurse"}} =
               Invites.create_invite(patient_user, attrs)
    end
  end

  describe "accept_invite/2" do
    test "when a provider accepts, it creates a care network link", %{
      patient_user: patient_user,
      nurse_user: nurse_user
    } do
      # Action: Patient invites nurse
      invite =
        Invites.create_invite(patient_user, %{
          "invitee_email" => nurse_user.email,
          "invitee_role" => "nurse",
          "patient_id" => patient_user.patient.id
        })
        |> elem(1)

      # Action: Nurse accepts invite
      assert {:ok, %Invite{status: "accepted"}} = Invites.accept_invite(nurse_user, invite)

      # Assert: The link between the nurse and patient now exists
      care_link =
        Repo.get_by!(CareNetwork, user_id: nurse_user.id, patient_id: patient_user.patient.id)

      assert care_link.relationship == "nurse"
    end

    test "when a new user accepts a patient invite, it creates a patient record and a link", %{
      doctor_user: doctor_user,
      new_user_to_be_patient: new_user_to_be_patient
    } do
      # Action: Doctor invites a new user to become a patient
      invite =
        Invites.create_invite(doctor_user, %{
          "invitee_email" => new_user_to_be_patient.email,
          "invitee_role" => "patient"
        })
        |> elem(1)

      # Action: The new user accepts the invite
      assert {:ok, %Invite{status: "accepted"}} =
               Invites.accept_invite(new_user_to_be_patient, invite)

      # Assert: A Patient record was created for the new user
      new_patient_record = Repo.get_by!(Patient, user_id: new_user_to_be_patient.id)
      assert new_patient_record

      # Assert: A CareNetwork link was created between the doctor and the new patient
      care_link =
        Repo.get_by!(CareNetwork, user_id: doctor_user.id, patient_id: new_patient_record.id)

      assert care_link.relationship == "doctor"
    end
  end

  describe "get_pending_invite_by_token/1" do
    test "returns a pending invite for a valid token", %{patient_user: patient_user} do
      {:ok, invite} =
        Invites.create_invite(patient_user, %{
          "invitee_email" => "test@example.com",
          "invitee_role" => "doctor",
          "patient_id" => patient_user.patient.id
        })

      found_invite = Invites.get_pending_invite_by_token(invite.token)
      assert found_invite.id == invite.id
    end

    test "get_pending_invite_by_token/1 returns nil for an expired invite", %{
      patient_user: patient_user
    } do
      {:ok, invite} =
        Invites.create_invite(patient_user, %{
          "invitee_email" => "test@example.com",
          "invitee_role" => "doctor",
          "patient_id" => patient_user.patient.id
        })

      expired_timestamp =
        DateTime.utc_now()
        |> DateTime.add(-1, :day)
        |> DateTime.truncate(:second)

      expired_invite =
        Ecto.Changeset.change(invite, expires_at: expired_timestamp)
        |> Repo.update!()

      assert Invites.get_pending_invite_by_token(expired_invite.token) == nil
    end
  end
end
