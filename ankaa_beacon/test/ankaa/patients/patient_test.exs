defmodule Ankaa.PatientsTest do
  @moduledoc """
  Test suite for Ankaa.Patients context.
  """
  use Ankaa.DataCase

  alias Ankaa.Patients
  alias Ankaa.Patients.Patient
  alias Ankaa.Patients.CareNetwork
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
        relationship: "doctor"
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

      {:ok, %{association: member}} =  Patients.create_patient_association(nurse1, patient1.patient, "nurse")

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
      assert {:ok, %{association: assoc}}  = Patients.create_patient_association(doctor, patient.patient, "doctor")

      assert assoc.user_id == doctor.id
      assert assoc.patient_id == patient.patient.id
      assert assoc.relationship == "doctor"
      assert assoc.permissions == ["receive_alerts"]
    end

    test "nurse can create association", %{nurse2: nurse2, patient1: patient} do
      assert {:ok, %{association: assoc}} = Patients.create_patient_association(nurse2, patient.patient, "nurse")

      assert assoc.relationship == "nurse"
      assert assoc.permissions == ["receive_alerts"]
    end

    test "regular user cannot create professional association", %{user: user, patient1: patient} do
      assert {:error, _reason} =
               Patients.create_patient_association(user, patient.patient, "caresupport")
    end

    test "patients can create peer associations", %{patient1: p1, patient2: p2} do
      assert {:ok, assoc} = Patients.create_peer_association(p1, p2.patient)
      assert assoc.relationship == "peer_support"
      assert assoc.permissions == ["receive_alerts"]
    end

    test "update_care_network_member/2 updates permissions", %{member: member} do
      new_permissions = ["manage_network", "view_vitals"]

      assert {:ok, %CareNetwork{} = updated_member} =
               Patients.update_care_network_member(member, %{permissions: new_permissions})

      assert updated_member.permissions == new_permissions
    end

    test "remove_care_network_member/1 deletes the association", %{member: member} do
      assert {:ok, %CareNetwork{}} = Patients.remove_care_network_member(member)

      assert_raise Ecto.NoResultsError, fn ->
        Patients.get_care_network_member!(member.id)
      end
    end
  end
  describe "organizations" do
    test "create_organization/1 creates an organization" do
      attrs = %{name: "Test Clinic", type: "clinic", npi_number: "1234567890"}
      assert {:ok, %Ankaa.Accounts.Organization{} = org} = Ankaa.Accounts.create_organization(attrs)
      assert org.name == "Test Clinic"
      assert org.npi_number == "1234567890"
    end

    test "assign_organization/2 assigns a user to an organization" do
      # 1. Setup
      {:ok, org} = Ankaa.Accounts.create_organization(%{name: "Test Org"})
      doctor = AccountsFixtures.doctor_fixture()

      # 2. Verify initial state
      assert is_nil(doctor.organization_id)

      # 3. Execute
      assert {:ok, updated_doctor} = Ankaa.Accounts.assign_organization(doctor, org.id)

      # 4. Verify result
      assert updated_doctor.organization_id == org.id
    end

    test "list_available_colleagues/2 returns colleagues in the same org" do
      # 1. Setup Organization
      {:ok, org} = Ankaa.Accounts.create_organization(%{name: "Davita Test"})

      # 2. Setup Doctor A (The inviter/current user)
      doctor_a = AccountsFixtures.doctor_fixture()
      {:ok, doctor_a} = Ankaa.Accounts.assign_organization(doctor_a, org.id)

      # 3. Setup Doctor B (The colleague to be found)
      doctor_b = AccountsFixtures.doctor_fixture()
      {:ok, _} = Ankaa.Accounts.assign_organization(doctor_b, org.id)

      # 4. Setup Nurse C (Another colleague)
      nurse_c = AccountsFixtures.nurse_fixture()
      {:ok, _} = Ankaa.Accounts.assign_organization(nurse_c, org.id)

      # 5. Setup Doctor D (Different Org - Should NOT be found)
      {:ok, other_org} = Ankaa.Accounts.create_organization(%{name: "Competitor"})
      doctor_d = AccountsFixtures.doctor_fixture()
      {:ok, _} = Ankaa.Accounts.assign_organization(doctor_d, other_org.id)

      # 6. Setup Patient (Target)
      patient = AccountsFixtures.patient_fixture()

      # 7. Test: List colleagues for Doctor A relative to this Patient
      colleagues = Patients.list_available_colleagues(doctor_a, patient.patient.id)

      # 8. Assertions
      assert length(colleagues) == 2
      assert Enum.any?(colleagues, & &1.id == doctor_b.id)
      assert Enum.any?(colleagues, & &1.id == nurse_c.id)
      refute Enum.any?(colleagues, & &1.id == doctor_d.id) # Wrong Org
      refute Enum.any?(colleagues, & &1.id == doctor_a.id) # Self
    end

    test "list_available_colleagues/2 filters out already assigned members" do
      {:ok, org} = Ankaa.Accounts.create_organization(%{name: "Clinic"})
      doctor_a = AccountsFixtures.doctor_fixture()
      doctor_b = AccountsFixtures.doctor_fixture()

      Ankaa.Accounts.assign_organization(doctor_a, org.id)
      Ankaa.Accounts.assign_organization(doctor_b, org.id)

      patient = AccountsFixtures.patient_fixture()

      # Assign Doctor B to the patient already
      {:ok, _} = Patients.create_patient_association(doctor_b, patient.patient, "doctor")

      # Now Doctor A looks for colleagues
      colleagues = Patients.list_available_colleagues(doctor_a, patient.patient.id)

      # Doctor B should NOT be in the list because they are already assigned
      assert Enum.empty?(colleagues)
    end
  end
end
