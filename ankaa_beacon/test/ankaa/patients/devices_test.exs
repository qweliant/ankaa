defmodule Ankaa.DevicesTest do
  use Ankaa.DataCase

  alias Ankaa.Devices
  alias Ankaa.Patients.Device
  alias Ankaa.AccountsFixtures

  describe "devices" do
    @valid_attrs %{
      type: "dialysis",
      model: "Sim-D400",
      simulation_scenario: "Normal"
    }
    @update_attrs %{
      type: "blood_pressure",
      model: "Sim-BP800",
      simulation_scenario: "HighSystolic"
    }
    @invalid_attrs %{type: nil, simulation_scenario: nil}

    setup do
      patient = AccountsFixtures.patient_fixture()
      %{patient: patient.patient}
    end

    test "list_devices_for_patient/1 returns all devices for patient", %{patient: patient} do
      device =
        %Device{patient_id: patient.id}
        |> Map.merge(@valid_attrs)
        |> Repo.insert!()

      assert Ankaa.Devices.list_devices_for_patient(patient.id) == [device]
    end

    test "get_device!/1 returns the device with given id", %{patient: patient} do
      device =
        %Device{patient_id: patient.id}
        |> Map.merge(@valid_attrs)
        |> Repo.insert!()

      assert Devices.get_device!(device.id) == device
    end

    test "create_device/1 with valid data creates a device", %{patient: patient} do
      attrs = Map.put(@valid_attrs, :patient_id, patient.id)
      assert {:ok, %Device{} = device} = Devices.create_device(attrs)
      assert device.type == "dialysis"
      assert device.model == "Sim-D400"
      assert device.simulation_scenario == "Normal"
      assert device.patient_id == patient.id
    end

    test "create_device/1 with invalid data returns error changeset", %{patient: patient} do
      attrs = Map.put(@invalid_attrs, :patient_id, patient.id)
      assert {:error, %Ecto.Changeset{}} = Devices.create_device(attrs)
    end

    test "update_device/2 with valid data updates the device", %{patient: patient} do
      device =
        %Device{patient_id: patient.id}
        |> Map.merge(@valid_attrs)
        |> Repo.insert!()

      assert {:ok, %Device{} = device} = Devices.update_device(device, @update_attrs)
      assert device.type == "blood_pressure"
      assert device.model == "Sim-BP800"
      assert device.simulation_scenario == "HighSystolic"
    end

    test "update_device/2 with invalid data returns error changeset", %{patient: patient} do
      device =
        %Device{patient_id: patient.id}
        |> Map.merge(@valid_attrs)
        |> Repo.insert!()

      assert {:error, %Ecto.Changeset{}} = Devices.update_device(device, @invalid_attrs)
      assert device == Devices.get_device!(device.id)
    end

    test "delete_device/1 deletes the device", %{patient: patient} do
      device =
        %Device{patient_id: patient.id}
        |> Map.merge(@valid_attrs)
        |> Repo.insert!()

      assert {:ok, %Device{}} = Devices.delete_device(device)
      assert_raise Ecto.NoResultsError, fn -> Devices.get_device!(device.id) end
    end

    test "change_device/1 returns a device changeset", %{patient: patient} do
      device =
        %Device{patient_id: patient.id}
        |> Map.merge(@valid_attrs)
        |> Repo.insert!()

      assert %Ecto.Changeset{} = Devices.change_device(device)
    end
  end
end
