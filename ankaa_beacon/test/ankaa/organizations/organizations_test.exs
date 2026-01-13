defmodule Ankaa.OrganizationTest do
  @moduledoc """
  Test suite for the Patients context.
  """
  use Ankaa.DataCase

  alias Ankaa.Patients
  alias Ankaa.AccountsFixtures

  describe "organizations" do
    test "create_organization/1 creates an organization" do
      attrs = %{name: "Test Clinic", type: "clinic", npi_number: "1234567890"}

      assert {:ok, %Ankaa.Community.Organization{} = org} =
               Ankaa.Communities.create_organization(attrs)

      assert org.name == "Test Clinic"
      assert org.npi_number == "1234567890"
    end

    test "assign_organization/2 assigns a user to an organization" do
      org = AccountsFixtures.organization_fixture()
      doctor = AccountsFixtures.doctor_fixture()
      refute Ankaa.Communities.get_membership(doctor.id, org.id)
      {:ok, _membership} = Ankaa.Communities.add_member(doctor, org.id, "member")
      assert Ankaa.Communities.get_membership(doctor.id, org.id)
    end

    test "list_available_colleagues/2 returns colleagues in the same org" do
      org = AccountsFixtures.organization_fixture()

      doctor_a = AccountsFixtures.doctor_fixture()
      doctor_b = AccountsFixtures.doctor_fixture()
      nurse = AccountsFixtures.nurse_fixture()
      outsider = AccountsFixtures.doctor_fixture()

      patient = AccountsFixtures.patient_fixture()

      AccountsFixtures.membership_fixture(doctor_a, org)
      AccountsFixtures.membership_fixture(doctor_b, org)
      AccountsFixtures.membership_fixture(nurse, org)

      colleagues = Patients.list_available_colleagues(doctor_a, patient.patient.id)

      assert length(colleagues) == 2

      assert Enum.any?(colleagues, fn c -> c.id == doctor_b.id end)
      assert Enum.any?(colleagues, fn c -> c.id == nurse.id end)
      refute Enum.any?(colleagues, fn c -> c.id == outsider.id end)
    end

    test "list_available_colleagues/2 filters out already assigned members" do
      org = AccountsFixtures.organization_fixture()
      doctor_a = AccountsFixtures.doctor_fixture()
      doctor_b = AccountsFixtures.doctor_fixture()

      Ankaa.Communities.add_member(doctor_a, org.id)
      Ankaa.Communities.add_member(doctor_b, org.id)

      patient = AccountsFixtures.patient_fixture()

      # Assign Doctor B to the patient first
      {:ok, _} = Patients.create_patient_association(doctor_b, patient.patient, "doctor")

      # Now Doctor A looks for colleagues
      colleagues = Patients.list_available_colleagues(doctor_a, patient.patient.id)

      # Doctor B should NOT be in the list because they are already assigned
      assert Enum.empty?(colleagues)
    end

    test "list_available_colleagues/2 does not add user to a new organization via care network association" do
      org = AccountsFixtures.organization_fixture()
      org2 = AccountsFixtures.organization_fixture()

      doctor = AccountsFixtures.doctor_fixture()
      Ankaa.Communities.add_member(doctor, org.id)

      nurse = AccountsFixtures.nurse_fixture()
      Ankaa.Communities.add_member(nurse, org2.id)

      patient = AccountsFixtures.patient_fixture()
      {:ok, _} = Patients.create_patient_association(doctor, patient.patient, "doctor")
      {:ok, _} = Patients.create_patient_association(nurse, patient.patient, "nurse")

      colleagues = Patients.list_available_colleagues(doctor, patient.patient.id)

      # assert that nurse is not included since they belong to a different org
      refute Enum.any?(colleagues, &(&1.id == nurse.id))

      # assert that patient user is only in their original org
      patient_user = Ankaa.Repo.get(Ankaa.Accounts.User, patient.id)
      assert Ankaa.Communities.get_membership(patient_user.id, org.id) == nil
    end
  end
end
