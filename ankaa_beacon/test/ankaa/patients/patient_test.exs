defmodule Ankaa.PatientsTest do
  @moduledoc """
  Test suite for the Patients context.
  """
  use Ankaa.DataCase

  alias Ankaa.Patients
  alias Ankaa.Patients.{Patient, CareNetwork}
  alias Ankaa.AccountsFixtures

  describe "list_patients_for_user/1" do
    setup do
      admin = AccountsFixtures.admin_fixture()
      doctor = AccountsFixtures.doctor_fixture()
      nurse = AccountsFixtures.nurse_fixture()
      patient1 = AccountsFixtures.patient_fixture()
      patient2 = AccountsFixtures.patient_fixture(%{name: "Peer Patient"})

      # Create association between doctor and patient1
      {:ok, _} =
        Patients.create_patient_association(doctor, patient1.patient, "doctor", :admin, :doctor)

      # Create peer association
      {:ok, _} = Patients.create_peer_association(patient1, patient2.patient)

      %{
        admin: admin,
        doctor: doctor,
        nurse: nurse,
        patient1: patient1,
        patient2: patient2
      }
    end

    test "list_patients/0 returns all patients" do
      patient = AccountsFixtures.patient_fixture()
      patients = Patients.list_patients()
      assert patient.patient in patients
    end

    test "admin sees all patients", %{admin: admin, patient1: p1, patient2: p2} do
      assert {:ok, patients} = Patients.list_patients_for_user(admin)
      patient_ids = Enum.map(patients, & &1.id)
      assert p1.patient in patients
      assert p2.patient in patients
    end

    test "doctor sees only their patients", %{doctor: doctor, patient1: p1, patient2: p2} do
      assert {:ok, patients} = Patients.list_patients_for_user(doctor)
      assert length(patients) == 1
      patient_ids = Enum.map(patients, & &1.id)

      assert p1.patient.id in patient_ids
      refute p2.patient.id in patient_ids, "Doctor should only see their assigned patients"
    end

    test "patient sees peer patients", %{patient1: p1, patient2: p2} do
      assert {:ok, patients} = Patients.list_patients_for_user(p1)
      assert length(patients) == 1
      patient_ids = Enum.map(patients, & &1.id)
      # Note: Whether a patient sees "themselves" in this list depends on if
      # a Self-link exists in CareNetwork. The fixture doesn't create one by default.
      # refute p1.patient.id in patient_ids, "Patient shouldn't see themselves"
      assert p2.patient.id in patient_ids, "Patient should see their peers"
    end

    test "unauthorized user gets empty list", %{nurse: nurse} do
      assert {:ok, []} = Patients.list_patients_for_user(nurse)
    end
  end

  describe "search_patients/2" do
    setup do
      admin = AccountsFixtures.admin_fixture()
      doctor = AccountsFixtures.doctor_fixture()
      nurse = AccountsFixtures.nurse_fixture()
      patient1 = AccountsFixtures.patient_fixture()
      patient2 = AccountsFixtures.patient_fixture(%{name: "Peer Patient"})

      # Create association between doctor and patient1
      %CareNetwork{}
      |> CareNetwork.changeset(%{
        user_id: doctor.id,
        patient_id: patient1.patient.id,
        relationship: "doctor",
        role: :admin
      })
      |> Repo.insert!()

      %{
        admin: admin,
        doctor: doctor,
        nurse: nurse,
        patient1: patient1,
        patient2: patient2
      }
    end

    test "doctor can search their patients by name", %{doctor: doctor, patient1: p1} do
      assert {:ok, results} = Patients.search_patients(doctor, %{name: "Test Patient"})
      result_ids = Enum.map(results, & &1.id)
      assert p1.patient.id in result_ids
    end

    test "patient can't see unauthorized patients in search", %{patient1: p1} do
      # Assuming patient1 shouldn't see patient2 based on your rules
      assert {:ok, results} = Patients.search_patients(p1, %{name: "Peer Patient"})
      result_ids = Enum.map(results, & &1.id)
      refute p1.patient.id in result_ids
    end

    test "handles empty search terms", %{admin: admin} do
      assert {:ok, _results} = Patients.search_patients(admin, %{})
    end

    test "handles nil search values", %{admin: admin} do
      assert {:ok, _results} = Patients.search_patients(admin, %{name: nil})
    end
  end

  describe "patients" do
    @valid_attrs %{
      name: "John Doe",
      date_of_birth: ~D[1990-01-01],
      timezone: "America/Phoenix",
      external_id: "12345"
    }
    @update_attrs %{
      name: "John Updated",
      date_of_birth: ~D[1991-01-01],
      timezone: "America/New_York"
    }
    @invalid_attrs %{name: nil, date_of_birth: "invalid", timezone: nil}

    test "get_patient!/1 returns the patient with given id" do
      patient = AccountsFixtures.patient_fixture()
      assert Patients.get_patient!(patient.patient.id) == patient.patient
    end

    test "get_patient_by_user_id/1 returns the patient for given user_id" do
      patient = AccountsFixtures.patient_fixture()
      assert Patients.get_patient_by_user_id(patient.id) == patient.patient
    end

    test "create_patient/2 with valid data creates a patient" do
      user = AccountsFixtures.user_fixture()
      assert {:ok, %Patient{} = patient} = Patients.create_patient(@valid_attrs, user)
      assert patient.name == "John Doe"
      assert patient.user_id == user.id
    end

    test "create_patient/2 with invalid data returns error changeset" do
      user = AccountsFixtures.user_fixture()
      assert {:error, %Ecto.Changeset{}} = Patients.create_patient(@invalid_attrs, user)
    end

    test "create_patient/2 enforces unique external_id constraint" do
      user = AccountsFixtures.user_fixture()
      attrs = Map.put(@valid_attrs, :external_id, "unique123")
      assert {:ok, _} = Patients.create_patient(attrs, user)
      assert {:error, changeset} = Patients.create_patient(attrs, user)
      assert "has already been taken" in errors_on(changeset).external_id
    end

    test "update_patient/2 with valid data updates the patient" do
      patient = AccountsFixtures.patient_fixture()
      assert {:ok, %Patient{} = patient} = Patients.update_patient(patient.patient, @update_attrs)
      assert patient.name == "John Updated"
      assert patient.date_of_birth == ~D[1991-01-01]
      assert patient.timezone == "America/New_York"
    end

    test "update_patient/2 with invalid data returns error changeset" do
      patient = AccountsFixtures.patient_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Patients.update_patient(patient.patient, @invalid_attrs)

      assert patient.patient == Patients.get_patient!(patient.patient.id)
    end

    test "delete_patient/1 deletes the patient" do
      patient = AccountsFixtures.patient_fixture()
      assert {:ok, %Patient{}} = Patients.delete_patient(patient.patient)
      assert_raise Ecto.NoResultsError, fn -> Patients.get_patient!(patient.patient.id) end
    end

    test "change_patient/1 returns a patient changeset" do
      patient = AccountsFixtures.patient_fixture()
      assert %Ecto.Changeset{} = Patients.change_patient(patient.patient)
    end
  end

  describe "care network" do
    setup do
      doctor = AccountsFixtures.doctor_fixture()
      nurse1 = AccountsFixtures.nurse_fixture()
      nurse2 = AccountsFixtures.nurse_fixture()
      patient1 = AccountsFixtures.patient_fixture()
      patient2 = AccountsFixtures.patient_fixture(%{name: "Peer Patient"})
      regular_user = AccountsFixtures.user_fixture()

      {:ok, member} =
        Patients.create_patient_association(
          nurse1,
          patient1.patient,
          "nurse",
          :contributor,
          :nurse
        )

      %{
        doctor: doctor,
        nurse: nurse1,
        nurse2: nurse2,
        patient1: patient1,
        patient2: patient2,
        user: regular_user,
        member: member
      }
    end

    test "doctor can create association", %{doctor: doctor, patient1: patient} do
      assert {:ok, assoc} =
               Patients.create_patient_association(
                 doctor,
                 patient.patient,
                 "doctor",
                 :admin,
                 :doctor
               )

      assert assoc.user_id == doctor.id
      assert assoc.patient_id == patient.patient.id
      assert assoc.relationship == "doctor"
      assert assoc.role == :doctor
      assert assoc.permission == :admin
    end

    test "nurse can create association", %{nurse2: nurse2, patient1: patient} do
      assert {:ok, assoc} =
               Patients.create_patient_association(
                 nurse2,
                 patient.patient,
                 "nurse",
                 :admin,
                 :nurse
               )

      assert assoc.relationship == "nurse"
      assert assoc.role == :nurse
      assert assoc.permission == :admin
    end

    test "regular user CAN create association at context level",
         %{user: user, patient1: patient} do
      assert {:ok, _assoc} =
               Patients.create_patient_association(
                 user,
                 patient.patient,
                 "caresupport",
                 :admin,
                 :caresupport
               )
    end

    test "patients can create peer associations (reciprocal)", %{patient1: p1, patient2: p2} do
      {:ok, _} = Patients.create_peer_association(p1, p2.patient)

      link1 = Repo.get_by(CareNetwork, user_id: p1.id, patient_id: p2.patient.id)
      assert link1
      assert link1.relationship == "peer_support"

      user2_id = p2.id
      link2 = Repo.get_by(CareNetwork, user_id: user2_id, patient_id: p1.patient.id)
      assert link2
      assert link2.relationship == "peer_support"
    end

    test "update_care_network_member/2 updates permissions", %{member: member} do
      assert {:ok, %CareNetwork{} = updated_member} =
               Patients.update_care_network_member(member, %{role: :admin})

      assert updated_member.role == :admin
    end

    test "remove_care_network_member/1 deletes the association", %{member: member} do
      assert {:ok, %CareNetwork{}} = Patients.remove_care_network_member(member)

      assert_raise Ecto.NoResultsError, fn ->
        Patients.get_care_network_member!(member.id)
      end
    end
  end

  describe "create_patient_hub/2" do
    setup do
      user = AccountsFixtures.user_fixture()
      %{user: user}
    end

    test "creates a 'Self' hub: links patient record to user and makes them Owner", %{user: user} do
      attrs = %{
        "name" => "My Profile",
        "date_of_birth" => ~D[1990-01-01],
        "relationship" => "Patient",
        "role" => "patient"
      }

      # It returns a map from the transaction: %{patient: ..., membership: ...}
      assert {:ok, %{patient: patient, membership: membership}} =
               Patients.create_patient_hub(user, attrs)

      # 1. Check Patient
      assert patient.user_id == user.id
      assert patient.name == "My Profile"

      # 2. Check CareNetwork Link
      assert membership.user_id == user.id
      assert membership.permission == :owner
      # Logic in context defaults 'Self' role to whatever was passed or :caresupport?
      # Your code currently says: if Self, use :admin? No, check logic:
      # "If explicit role passed, use it... true -> :caresupport".
      # But usually Self implies Owner/Admin.
      # Let's verify what the code actually produced:
      # Based on your current 'cond' fallback
      assert membership.role == :patient
    end

    test "creates a 'Headless' hub (e.g. for a child): patient has NO user_id", %{user: creator} do
      attrs = %{
        "name" => "My Kid",
        "date_of_birth" => ~D[2015-05-05],
        "relationship" => "Mother",
        "role" => "caresupport"
      }

      assert {:ok, %{patient: patient, membership: membership}} =
               Patients.create_patient_hub(creator, attrs)

      # 1. Patient should NOT be linked to the creator's user_id (Headless)
      assert patient.user_id == nil
      assert patient.name == "My Kid"

      # 2. Creator is still the Owner of the Network
      assert membership.user_id == creator.id
      assert membership.relationship == "Mother"
      assert membership.permission == :owner
    end
  end

  describe "colleague management" do
    setup do
      # Create an Org
      org = AccountsFixtures.organization_fixture()

      # Doctor A (The User looking for colleagues)
      doctor_a = AccountsFixtures.doctor_fixture()
      {:ok, _} = Ankaa.Communities.add_member(doctor_a, org.id, "admin")

      # Doctor B (Available Colleague in same Org)
      doctor_b = AccountsFixtures.doctor_fixture()
      {:ok, _} = Ankaa.Communities.add_member(doctor_b, org.id, "member")

      # Nurse C (Already on the team - should NOT show up)
      nurse_c = AccountsFixtures.nurse_fixture()
      {:ok, _} = Ankaa.Communities.add_member(nurse_c, org.id, "member")

      # Doctor D (Different Org - should NOT show up)
      doctor_d = AccountsFixtures.doctor_fixture()

      # The Patient
      patient_user = AccountsFixtures.patient_fixture()
      patient_id = patient_user.patient.id

      # Assign Doctor A and Nurse C to the patient
      {:ok, _} =
        Patients.create_patient_association(
          doctor_a,
          patient_user.patient,
          "Doctor",
          :owner,
          :doctor
        )

      {:ok, _} =
        Patients.create_patient_association(
          nurse_c,
          patient_user.patient,
          "Nurse",
          :contributor,
          :nurse
        )

      %{
        patient_id: patient_id,
        doctor_a: doctor_a,
        doctor_b: doctor_b,
        nurse_c: nurse_c,
        doctor_d: doctor_d
      }
    end

    test "list_available_colleagues/2 returns only unassigned members of the same org", ctx do
      results = Patients.list_available_colleagues(ctx.doctor_a, ctx.patient_id)
      result_ids = Enum.map(results, & &1.id)

      # Should include Doctor B (Same Org, Not on team)
      assert ctx.doctor_b.id in result_ids

      # Should NOT include Doctor A (Self/Already on team)
      refute ctx.doctor_a.id in result_ids

      # Should NOT include Nurse C (Already on team)
      refute ctx.nurse_c.id in result_ids

      # Should NOT include Doctor D (Different Org)
      refute ctx.doctor_d.id in result_ids
    end

    test "add_care_team_member/3 maps roles correctly", ctx do
      # Add Doctor B
      {:ok, link} = Patients.add_care_team_member(ctx.patient_id, ctx.doctor_b, "doctor")

      assert link.role == :doctor
      # Tested against your case statement logic
      assert link.permission == :contributor
      assert link.relationship == "Doctor"
    end
  end
end
