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
      admin_user = AccountsFixtures.admin_fixture()
      %{user: doctor_user} = AccountsFixtures.doctor_fixture()
      %{user: nurse_user} = AccountsFixtures.nurse_fixture()

      %{user: patient1_user, patient: patient1_record} = AccountsFixtures.patient_fixture()

      %{user: patient2_user, patient: patient2_record} =
        AccountsFixtures.patient_fixture(%{name: "Peer Patient"})

      {:ok, _} =
        Patients.create_patient_association(
          doctor_user,
          patient1_record,
          "doctor",
          :admin,
          :doctor
        )

      {:ok, _} = Patients.create_peer_association(patient1_user, patient2_record)

      %{
        admin: admin_user,
        doctor: doctor_user,
        nurse: nurse_user,
        patient1_user: patient1_user,
        patient1_record: patient1_record,
        patient2_user: patient2_user,
        patient2_record: patient2_record
      }
    end

    test "list_patients/0 returns all patients", %{patient1_record: p1} do
      patients = Patients.list_patients()
      ids = Enum.map(patients, & &1.id)
      assert p1.id in ids
    end

    # test "admin sees all patients", %{admin: admin, patient1_record: p1, patient2_record: p2} do
    #   assert {:ok, patients} = Patients.list_patients_for_user(admin)
    #   ids = Enum.map(patients, & &1.id)
    #   assert p1.id in ids
    #   assert p2.id in ids
    # end

    test "doctor sees only their patients", %{
      doctor: doctor,
      patient1_record: p1,
      patient2_record: p2
    } do
      assert {:ok, patients} = Patients.list_patients_for_user(doctor)
      ids = Enum.map(patients, & &1.id)

      assert p1.id in ids
      refute p2.id in ids
    end

    test "patient sees peer patients", %{patient1_user: p1_user, patient2_record: p2_rec} do
      assert {:ok, patients} = Patients.list_patients_for_user(p1_user)
      ids = Enum.map(patients, & &1.id)
      assert p2_rec.id in ids
    end

    test "unauthorized user gets empty list", %{nurse: nurse} do
      stranger = AccountsFixtures.user_fixture()
      assert {:ok, []} = Patients.list_patients_for_user(stranger)
    end
  end

  describe "search_patients/2" do
    setup do
      %{user: doctor_user} = AccountsFixtures.doctor_fixture()
      admin_user = AccountsFixtures.admin_fixture()
      %{patient: patient_record} = AccountsFixtures.patient_fixture()


      {:ok, _} =
        Patients.create_patient_association(
          doctor_user,
          patient_record,
          "doctor",
          :admin,
          :doctor
        )

      %{doctor: doctor_user, admin: admin_user, patient: patient_record}
    end

    test "doctor can search their patients by name", %{doctor: doctor, patient: p} do
      assert {:ok, results} = Patients.search_patients(doctor, %{name: "Test Patient"})
      ids = Enum.map(results, & &1.id)
      assert p.id in ids
    end

    test "handles empty search terms", %{admin: admin} do
      assert {:ok, _results} = Patients.search_patients(admin, %{})
    end
  end

  describe "patients CRUD" do
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

    setup do
      %{user: user, patient: patient} = AccountsFixtures.patient_fixture()
      update_user = AccountsFixtures.user_fixture()

      %{
        user: user,
        patient: patient,
        update_user: update_user
      }
    end

    test "get_patient!/1 returns the patient with given id", %{patient: patient} do
      assert Patients.get_patient!(patient.id) == patient
    end

    test "get_patient_by_user_id/1 returns the patient for given user_id", %{
      user: user,
      patient: patient
    } do
      assert Patients.get_patient_by_user_id(user.id) == patient
    end

    test "create_patient/2 with valid data creates a patient", %{user: user} do
      assert {:ok, %Patient{} = patient} = Patients.create_patient(@valid_attrs, user)
      assert patient.name == "John Doe"
      assert patient.user_id == user.id
    end

    test "create_patient/2 with invalid data returns error changeset", %{user: user} do
      assert {:error, %Ecto.Changeset{}} = Patients.create_patient(@invalid_attrs, user)
    end

    test "create_patient/2 enforces unique external_id constraint", %{user: user} do
      attrs = Map.put(@valid_attrs, :external_id, "unique123")
      assert {:ok, _} = Patients.create_patient(attrs, user)
      assert {:error, changeset} = Patients.create_patient(attrs, user)
      assert "has already been taken" in errors_on(changeset).external_id
    end

    test "update_patient/2 with valid data updates the patient", %{patient: patient} do
      assert {:ok, %Patient{} = patient} = Patients.update_patient(patient, @update_attrs)
      assert patient.name == "John Updated"
      assert patient.date_of_birth == ~D[1991-01-01]
      assert patient.timezone == "America/New_York"
    end

    test "update_patient/2 with invalid data returns error changeset", %{patient: patient} do
      assert {:error, %Ecto.Changeset{}} =
               Patients.update_patient(patient, @invalid_attrs)

      assert patient == Patients.get_patient!(patient.id)
    end

    test "delete_patient/1 deletes the patient", %{patient: patient} do
      assert {:ok, %Patient{}} = Patients.delete_patient(patient)
      assert_raise Ecto.NoResultsError, fn -> Patients.get_patient!(patient.id) end
    end

    test "change_patient/1 returns a patient changeset", %{patient: patient} do
      assert %Ecto.Changeset{} = Patients.change_patient(patient)
    end
  end

  describe "care network" do
    setup do
      %{user: doctor_user} = AccountsFixtures.doctor_fixture()
      %{user: nurse1_user} = AccountsFixtures.nurse_fixture()
      %{user: nurse2_user} = AccountsFixtures.nurse_fixture()

      %{user: patient1_user, patient: patient1_record} = AccountsFixtures.patient_fixture()

      %{user: patient2_user, patient: patient2_record} =
        AccountsFixtures.patient_fixture(%{name: "Peer Patient"})

      {:ok, member} =
        Patients.create_patient_association(
          nurse1_user,
          patient1_record,
          "nurse",
          :contributor,
          :nurse
        )

      %{
        doctor: doctor_user,
        nurse1: nurse1_user,
        nurse2: nurse2_user,
        patient1_user: patient1_user,
        patient1_record: patient1_record,
        patient2_user: patient2_user,
        patient2_record: patient2_record,
        member: member
      }
    end

    test "doctor can create association", %{doctor: doctor, patient1_record: p_record} do
      assert {:ok, assoc} =
               Patients.create_patient_association(doctor, p_record, "doctor", :admin, :doctor)

      assert assoc.role == :doctor
      assert assoc.permission == :admin
    end

    test "nurse can create association", %{nurse2: nurse, patient1_record: p_record} do
      assert {:ok, assoc} =
               Patients.create_patient_association(nurse, p_record, "nurse", :admin, :nurse)

      assert assoc.role == :nurse
    end

    test "patients can create peer associations", %{
      patient1_user: p1_user,
      patient2_record: p2_rec
    } do
      assert {:ok, _} = Patients.create_peer_association(p1_user, p2_rec)
      assert Repo.get_by(CareNetwork, user_id: p1_user.id, patient_id: p2_rec.id)
    end

    test "update_care_network_member/2 updates permissions", %{member: member} do
      assert {:ok, updated_member} =
               Patients.update_care_network_member(member, %{permission: :admin})

      assert updated_member.permission == :admin
    end

    test "remove_care_network_member/1 deletes the association", %{member: member} do
      assert {:ok, _} = Patients.remove_care_network_member(member)

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
      org = AccountsFixtures.organization_fixture()

      # 1. Doctor A (The Searcher)
      %{user: doctor_a} = AccountsFixtures.doctor_fixture()
      {:ok, _} = Ankaa.Communities.add_member(doctor_a, org.id, "admin")

      # 2. Doctor B (The Colleague)
      %{user: doctor_b} = AccountsFixtures.doctor_fixture()
      {:ok, _} = Ankaa.Communities.add_member(doctor_b, org.id, "member")

      # 3. Nurse C (The Teammate)
      %{user: nurse_c} = AccountsFixtures.nurse_fixture()
      {:ok, _} = Ankaa.Communities.add_member(nurse_c, org.id, "member")

      # 4. Doctor D (Outsider)
      %{user: doctor_d} = AccountsFixtures.doctor_fixture()

      # 5. Patient Setup
      %{user: _p_user, patient: patient_record} = AccountsFixtures.patient_fixture()
      Patients.create_patient_association(doctor_a, patient_record, "Doctor", :owner, :doctor)
      Patients.create_patient_association(nurse_c, patient_record, "Nurse", :contributor, :nurse)

      # Reload Doctor A so they see their Org Membership
      doctor_a_reloaded = Ankaa.Repo.preload(doctor_a, [:care_network, :organizations])

      %{
        patient_id: patient_record.id,
        doctor_a: doctor_a_reloaded,
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
