defmodule Ankaa.InvitesTest do
  @moduledoc """
  Tests for the Invites context.
  """
  use Ankaa.DataCase, async: true

  alias Ankaa.Invites
  alias Ankaa.Notifications.Invite
  alias Ankaa.Patients.{CareNetwork, Patient}
  alias Ankaa.AccountsFixtures

  setup do
    # 1. Destructure the Patient Wrapper
    %{user: patient_user, patient: patient_record} = AccountsFixtures.patient_fixture()

    # 2. Setup "Patient Hub" (which is just an Organization in this context?)
    # Wait, in your code 'patient_hub' seems to be an Organization.
    # Let's call it 'org' to be clear.
    org = AccountsFixtures.organization_fixture()

    # 3. Add patient_user to Org (Passing the STRUCT, not the wrapper)
    {:ok, _assoc} = Ankaa.Communities.add_member(patient_user, org.id, "admin")

    # 4. Destructure Doctor/Nurse Wrappers
    %{user: doctor_user} = AccountsFixtures.doctor_fixture()
    %{user: nurse_user} = AccountsFixtures.nurse_fixture()

    # 5. Destructure New User Wrapper
    new_user_to_be_patient =
      AccountsFixtures.user_fixture(%{email: "new.patient@example.com"})

    %{
      patient_user: patient_user,
      patient_record: patient_record,
      doctor_user: doctor_user,
      nurse_user: nurse_user,
      new_user_to_be_patient: new_user_to_be_patient,
      patient_hub: org
    }
  end

  describe "create_invite/2" do
    test "a doctor can create an invite for a NEW patient", %{
      doctor_user: doctor_user,
      new_user_to_be_patient: new_user_to_be_patient
    } do
      attrs = %{
        "invitee_email" => new_user_to_be_patient.email,
        "invitee_role" => "patient",
        "invitee_permission" => "owner",
        "patient_id" => nil
      }

      {:ok, invite} = Invites.create_invite(doctor_user, attrs)

      assert invite.invitee_email == new_user_to_be_patient.email
      assert invite.invitee_role == "patient"
      assert invite.invitee_permission == "owner"
      assert invite.status == "pending"
    end

    test "a patient can create an invite for a nurse", %{
      patient_user: patient_user,
      nurse_user: nurse
    } do
      attrs = %{
        "invitee_email" => nurse.email,
        "invitee_role" => "nurse",
        "patient_id" => patient_user.patient.id,
        "invitee_permission" => "contributor"
      }

      assert {:ok, %Invite{invitee_role: "nurse"}} =
               Invites.create_invite(patient_user, attrs)
    end

    test "a doctor can create an invite for a nurse to join a patient's care network and inviters org",
         %{
           doctor_user: doctor_user,
           nurse_user: nurse,
           patient_user: patient_user,
           patient_hub: patient_hub
         } do
      # add the doctor to the org, then invite the nurse to the org with a specific role
      {:ok, _membership} = Ankaa.Communities.add_member(doctor_user, patient_hub.id, "admin")

      attrs = %{
        "invitee_email" => nurse.email,
        "invitee_role" => "nurse",
        "invitee_permission" => "contributor",
        "patient_id" => patient_user.patient.id,
        "organization_id" => patient_hub.id
      }

      {:ok, invite} = Invites.create_invite(doctor_user, attrs)

      assert invite.invitee_role == "nurse"
      assert invite.organization_id == patient_hub.id
      assert invite.patient_id == patient_user.patient.id
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
          "patient_id" => patient_user.patient.id,
          "invitee_permission" => :contributor,
          "invitee_relationship" => "Nurse"
        })
        |> elem(1)

      # Action: Nurse accepts invite
      assert {:ok, %Invite{status: "accepted"}} = Invites.accept_invite(nurse_user, invite)

      # Assert: The link between the nurse and patient now exists
      care_link =
        Repo.get_by!(CareNetwork, user_id: nurse_user.id, patient_id: patient_user.patient.id)

      assert care_link.relationship == "Nurse"
    end

    test "when a new user accepts a patient invite, it creates a patient record and a link" do
      %{user: doctor} = Ankaa.AccountsFixtures.doctor_fixture()
      unexisting_users_email = "unexisting_user@example.com"

      # Action: Doctor invites a new user to become a patient
      invite =
        Invites.create_invite(doctor, %{
          "invitee_email" => unexisting_users_email,
          "invitee_permission" => :viewer,
          "invitee_role" => "patient",
          "invitee_relationship" => "Patient of Dr. #{doctor.first_name} #{doctor.last_name}",
          "patient_id" => nil
        })
        |> elem(1)

      # middleware handles rerouting users if they are not a user. i can expect a user to exist
      new_user = Ankaa.AccountsFixtures.user_fixture(%{email: unexisting_users_email})

      # Action: The new user accepts the invite
      assert {:ok, %Invite{status: "accepted"}} =
               Invites.accept_invite(new_user, invite)

      # Assert: A Patient record was created for the new user
      new_patient_record = Repo.get_by!(Patient, user_id: new_user.id)
      assert new_patient_record

      # Assert: A CareNetwork link was created between the doctor and the new patient
      care_link =
        Repo.get_by!(CareNetwork, user_id: doctor.id, patient_id: new_patient_record.id)

      assert care_link.relationship == "Patient of Dr. #{doctor.first_name} #{doctor.last_name}"

      assert care_link.permission == :viewer
    end

    test "accepts as care support: links user to existing patient hub", %{
      patient_user: patient_user,
      doctor_user: doctor_user
    } do
      caregiver_user = AccountsFixtures.user_fixture(%{email: "mom@example.com"})

      # Action: Doctor invites a family member (Care Support)
      invite =
        Invites.create_invite(doctor_user, %{
          "invitee_email" => caregiver_user.email,
          "invitee_role" => "caresupport",
          "invitee_relationship" => "Mother",
          "patient_id" => patient_user.patient.id,
          "invitee_permission" => :contributor
        })
        |> elem(1)

      # Action: Caregiver accepts
      assert {:ok, %Invite{status: "accepted"}} = Invites.accept_invite(caregiver_user, invite)

      # Assert: CareNetwork link created between Caregiver and Patient
      link =
        Repo.get_by!(CareNetwork, user_id: caregiver_user.id, patient_id: patient_user.patient.id)

      assert link.role == :caresupport
      assert link.relationship == "Mother"
      assert link.permission == :contributor
    end

    test "works as colleague (doctor) without patient_id: joins organization only", %{
      doctor_user: doctor_user,
      patient_hub: hub
    } do
      new_colleague = AccountsFixtures.user_fixture(%{email: "colleague@hospital.com"})

      invite =
        Invites.create_invite(doctor_user, %{
          "invitee_email" => new_colleague.email,
          "invitee_role" => "doctor",
          "organization_id" => hub.id,
          "patient_id" => nil,
          "invitee_permission" => :admin,
          "invitee_relationship" => "Colleague"
        })
        |> elem(1)

      assert {:ok, %Invite{status: "accepted"}} = Invites.accept_invite(new_colleague, invite)

      membership =
        Repo.get_by!(Ankaa.Community.OrganizationMembership,
          user_id: new_colleague.id,
          organization_id: hub.id
        )

      assert membership.role == "member"

      refute Repo.get_by(CareNetwork, user_id: new_colleague.id)
    end

    test "when existing user accepts an invite as the patient invite but had no patient record previously",
         %{
           doctor_user: doctor_user
         } do
      # Scenario: A user signed up via the website, but never created a patient profile.
      # The doctor invites them to be a patient.
      existing_user_no_patient = AccountsFixtures.user_fixture(%{email: "headless_user@example.com"})

      # Verify precondition: No patient record exists
      refute Repo.get_by(Patient, user_id: existing_user_no_patient.id)

      invite =
        Invites.create_invite(doctor_user, %{
          "invitee_email" => existing_user_no_patient.email,
          "invitee_role" => "patient",
          "invitee_permission" => :viewer,
          "invitee_relationship" => "Patient of Dr. #{doctor_user.last_name}",
          "patient_id" => nil
        })
        |> elem(1)

      # Verify precondition: Invite is pending
      sent_invite = Invites.get_pending_invite_by_token(invite.token)
      assert sent_invite.id == invite.id

      # Action: Accept
      assert {:ok, _} = Invites.accept_invite(existing_user_no_patient, invite)

      # Assert: Patient record was created dynamically
      assert Repo.get_by(Patient, user_id: existing_user_no_patient.id)
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
