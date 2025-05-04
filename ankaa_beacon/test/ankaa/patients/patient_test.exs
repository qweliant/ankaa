# test/ankaa/patients/patients_test.exs
defmodule Ankaa.PatientsTest do
  use Ankaa.DataCase

  alias Ankaa.Patients
  alias Ankaa.Patients.{Patient, PatientAssociation, Device}
  alias Ankaa.AccountsFixtures

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

    test "list_all_patients/1 returns all patients for admins only" do
      admin = AccountsFixtures.admin_fixture()
      regular_user = AccountsFixtures.user_fixture()

      patient1 = AccountsFixtures.patient_fixture()
      patient2 = AccountsFixtures.patient_fixture(%{name: "Second Patient"})

      # Admin can see all patients
      assert patients = Patients.list_all_patients(admin)
      assert length(patients) >= 2
      assert patient1.patient in patients
      assert patient2.patient in patients

      # Regular user gets unauthorized
      assert {:error, :unauthorized} = Patients.list_all_patients(regular_user)
    end

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

  describe "devices" do
    @valid_device_attrs %{
      type: "mobile",
      model: "iPhone 12",
      device_id: "device123"
    }
    @update_device_attrs %{
      type: "tablet",
      model: "iPad Pro",
      device_id: "device456"
    }
    @invalid_device_attrs %{type: nil, model: nil, device_id: nil}

    test "list_devices_for_patient/1 returns all devices for patient" do
      patient = AccountsFixtures.patient_fixture()

      device =
        %Device{patient_id: patient.patient.id}
        |> Map.merge(@valid_device_attrs)
        |> Repo.insert!()

      assert Patients.list_devices_for_patient(patient.patient.id) == [device]
    end

    test "get_device!/1 returns the device with given id" do
      patient = AccountsFixtures.patient_fixture()

      device =
        %Device{patient_id: patient.patient.id}
        |> Map.merge(@valid_device_attrs)
        |> Repo.insert!()

      assert Patients.get_device!(device.id) == device
    end

    test "create_device/1 with valid data creates a device" do
      patient = AccountsFixtures.patient_fixture()
      attrs = Map.put(@valid_device_attrs, :patient_id, patient.patient.id)
      assert {:ok, %Device{} = device} = Patients.create_device(attrs)
      assert device.type == "mobile"
      assert device.model == "iPhone 12"
      assert device.device_id == "device123"
      assert device.patient_id == patient.patient.id
    end

    test "create_device/1 with invalid data returns error changeset" do
      patient = AccountsFixtures.patient_fixture()
      attrs = Map.put(@invalid_device_attrs, :patient_id, patient.patient.id)
      assert {:error, %Ecto.Changeset{}} = Patients.create_device(attrs)
    end

    test "create_device/1 enforces unique device_id constraint" do
      patient = AccountsFixtures.patient_fixture()
      attrs = Map.put(@valid_device_attrs, :patient_id, patient.patient.id)
      assert {:ok, _} = Patients.create_device(attrs)
      assert {:error, changeset} = Patients.create_device(attrs)
      assert "has already been taken" in errors_on(changeset).device_id
    end

    test "update_device/2 with valid data updates the device" do
      patient = AccountsFixtures.patient_fixture()

      device =
        %Device{patient_id: patient.patient.id}
        |> Map.merge(@valid_device_attrs)
        |> Repo.insert!()

      assert {:ok, %Device{} = device} = Patients.update_device(device, @update_device_attrs)
      assert device.type == "tablet"
      assert device.model == "iPad Pro"
      assert device.device_id == "device456"
    end

    test "update_device/2 with invalid data returns error changeset" do
      patient = AccountsFixtures.patient_fixture()

      device =
        %Device{patient_id: patient.patient.id}
        |> Map.merge(@valid_device_attrs)
        |> Repo.insert!()

      assert {:error, %Ecto.Changeset{}} = Patients.update_device(device, @invalid_device_attrs)
      assert device == Patients.get_device!(device.id)
    end

    test "delete_device/1 deletes the device" do
      patient = AccountsFixtures.patient_fixture()

      device =
        %Device{patient_id: patient.patient.id}
        |> Map.merge(@valid_device_attrs)
        |> Repo.insert!()

      assert {:ok, %Device{}} = Patients.delete_device(device)
      assert_raise Ecto.NoResultsError, fn -> Patients.get_device!(device.id) end
    end

    test "change_device/1 returns a device changeset" do
      patient = AccountsFixtures.patient_fixture()

      device =
        %Device{patient_id: patient.patient.id}
        |> Map.merge(@valid_device_attrs)
        |> Repo.insert!()

      assert %Ecto.Changeset{} = Patients.change_device(device)
    end
  end

  describe "patient associations" do
    test "associations are created and retrieved correctly" do
      patient = AccountsFixtures.patient_fixture()
      caregiver = AccountsFixtures.caregiver_fixture()

      # Test would normally use context functions, but since they're not shown,
      # we'll test the schema functionality directly
      attrs = %{
        relationship: "caregiver",
        can_alert: true,
        patient_id: patient.patient.id,
        user_id: caregiver.id
      }

      assert {:ok, association} =
               %PatientAssociation{}
               |> PatientAssociation.changeset(attrs)
               |> Repo.insert()

      assert association.relationship == "caregiver"
      assert association.can_alert == true
      assert association.patient_id == patient.patient.id
      assert association.user_id == caregiver.id

      # Test the through association
      patient = patient.patient |> Repo.preload(:associated_users)
      assert caregiver in patient.associated_users
    end

    test "enforces unique user-patient constraint" do
      patient = AccountsFixtures.patient_fixture()
      caregiver = AccountsFixtures.caregiver_fixture()

      attrs = %{
        relationship: "caregiver",
        patient_id: patient.patient.id,
        user_id: caregiver.id
      }

      assert {:ok, _} =
               %PatientAssociation{}
               |> PatientAssociation.changeset(attrs)
               |> Repo.insert()

      assert {:error, changeset} =
               %PatientAssociation{}
               |> PatientAssociation.changeset(attrs)
               |> Repo.insert()

      assert "Association between this user and patient already exists" in errors_on(changeset).user_id
    end
  end
end
