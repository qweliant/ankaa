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
      {:ok, _} = Patients.create_patient_association(doctor, patient1.patient, "doctor")

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
      assert length(patients) >= 2
      assert p1.patient in patients
      assert p2.patient in patients
    end

    test "doctor sees only their patients", %{doctor: doctor, patient1: p1, patient2: p2} do
      assert {:ok, patients} = Patients.list_patients_for_user(doctor)
      assert length(patients) == 1
      assert p1.patient in patients
      refute p2.patient in patients, "Doctor should only see their assigned patients"
    end

    test "patient sees peer patients", %{patient1: p1, patient2: p2} do
      assert {:ok, patients} = Patients.list_patients_for_user(p1)
      assert length(patients) == 1
      refute p1.patient in patients, "Patient shouldn't see themselves"
      assert p2.patient in patients, "Patient should see their peers"
    end

    test "unauthorized user gets error" do
      user = AccountsFixtures.user_fixture()
      assert {:error, :unauthorized} = Patients.list_patients_for_user(user)
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
      assert p1.patient in results
    end

    test "patient can't see unauthorized patients in search", %{patient1: p1} do
      # Assuming patient1 shouldn't see patient2 based on your rules
      assert {:ok, results} = Patients.search_patients(p1, %{name: "Peer Patient"})
      refute p1.patient in results
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
      assert patient.date_of_birth == ~D[1990-01-01]
      assert patient.timezone == "America/Phoenix"
      assert patient.external_id == "12345"
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

      {:ok, member} = Patients.create_patient_association(nurse1, patient1.patient, "nurse", :contributor)

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
      assert {:ok, assoc} = Patients.create_patient_association(doctor, patient.patient, "doctor", :admin)
      assert assoc.user_id == doctor.id
      assert assoc.patient_id == patient.patient.id
      assert assoc.relationship == "doctor"
      assert assoc.role == :admin
    end

    test "nurse can create association", %{nurse2: nurse2, patient1: patient} do
      assert {:ok, assoc} = Patients.create_patient_association(nurse2, patient.patient, "nurse", :admin)
      assert assoc.relationship == "nurse"
      assert assoc.role == :admin
    end

    test "regular user cannot create professional association", %{user: user, patient1: patient} do
      assert {:error, _reason} =
               Patients.create_patient_association(user, patient.patient, "caresupport")
    end

    test "patients can create peer associations", %{patient1: p1, patient2: p2} do
      assert {:ok, assoc} = Patients.create_peer_association(p1, p2.patient)
      assert assoc.relationship == "peer_support"
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
end
