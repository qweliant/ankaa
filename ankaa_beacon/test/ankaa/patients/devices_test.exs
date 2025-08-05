defmodule Ankaa.DevicesTest do
  use Ankaa.DataCase

  alias Ankaa.Patients
  alias Ankaa.Patients.{Device}
  alias Ankaa.AccountsFixtures

  describe "devices" do
    @valid_device_attrs %{
      type: "dialysis",
      model: "mock-device",
      device_id: "device123"
    }
    @update_device_attrs %{
      type: "blood_pressure",
      model: "mock-bp-device",
      device_id: "device456"
    }
    @invalid_device_attrs %{type: nil, model: nil, device_id: nil}

    setup do
      patient = AccountsFixtures.patient_fixture()
      %{patient: patient}
    end

    test "list_devices_for_patient/1 returns all devices for patient", %{patient: patient} do
      device =
        %Device{patient_id: patient.patient.id}
        |> Map.merge(@valid_device_attrs)
        |> Repo.insert!()

      assert Patients.list_devices_for_patient(patient.patient.id) == [device]
    end

    test "get_device!/1 returns the device with given id", %{patient: patient} do
      device =
        %Device{patient_id: patient.patient.id}
        |> Map.merge(@valid_device_attrs)
        |> Repo.insert!()

      assert Patients.get_device!(device.id) == device
    end

    test "create_device/1 with valid data creates a device", %{patient: patient} do
      attrs = Map.put(@valid_device_attrs, :patient_id, patient.patient.id)
      assert {:ok, %Device{} = device} = Patients.create_device(attrs)
      assert device.type == "dialysis"
      assert device.model == "mock-device"
      assert device.device_id == "device123"
      assert device.patient_id == patient.patient.id
    end

    test "create_device/1 with invalid data returns error changeset", %{patient: patient} do
      attrs = Map.put(@invalid_device_attrs, :patient_id, patient.patient.id)
      assert {:error, %Ecto.Changeset{}} = Patients.create_device(attrs)
    end

    test "create_device/1 enforces unique device_id constraint", %{patient: patient} do
      attrs = Map.put(@valid_device_attrs, :patient_id, patient.patient.id)
      assert {:ok, _} = Patients.create_device(attrs)
      assert {:error, changeset} = Patients.create_device(attrs)
      assert "has already been taken" in errors_on(changeset).device_id
    end

    test "update_device/2 with valid data updates the device", %{patient: patient} do
      device =
        %Device{patient_id: patient.patient.id}
        |> Map.merge(@valid_device_attrs)
        |> Repo.insert!()

      assert {:ok, %Device{} = device} = Patients.update_device(device, @update_device_attrs)
      assert device.type == "blood_pressure"
      assert device.model == "mock-bp-device"
      assert device.device_id == "device456"
    end

    test "update_device/2 with invalid data returns error changeset", %{patient: patient} do
      device =
        %Device{patient_id: patient.patient.id}
        |> Map.merge(@valid_device_attrs)
        |> Repo.insert!()

      assert {:error, %Ecto.Changeset{}} = Patients.update_device(device, @invalid_device_attrs)
      assert device == Patients.get_device!(device.id)
    end

    test "delete_device/1 deletes the device", %{patient: patient} do
      device =
        %Device{patient_id: patient.patient.id}
        |> Map.merge(@valid_device_attrs)
        |> Repo.insert!()

      assert {:ok, %Device{}} = Patients.delete_device(device)
      assert_raise Ecto.NoResultsError, fn -> Patients.get_device!(device.id) end
    end

    test "change_device/1 returns a device changeset", %{patient: patient} do
      device =
        %Device{patient_id: patient.patient.id}
        |> Map.merge(@valid_device_attrs)
        |> Repo.insert!()

      assert %Ecto.Changeset{} = Patients.change_device(device)
    end

    test "get_patient_by_device_id/1 returns the patient for given device_id", %{patient: patient} do
      attrs = Map.put(@valid_device_attrs, :patient_id, patient.patient.id)
      {:ok, device} = Patients.create_device(attrs)

      result = Patients.get_patient_by_device_id(device.device_id)
      assert result.id == patient.patient.id
    end
  end
end
