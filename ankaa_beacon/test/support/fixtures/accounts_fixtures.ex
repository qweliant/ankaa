defmodule Ankaa.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ankaa.Accounts` context.
  """

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def valid_user_password, do: "hello world!123"

  @doc """
  Generate a unique user email.
  """
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: unique_user_email(),
        password: valid_user_password()
      })
      |> Ankaa.Accounts.register_user()

    # If a role was provided in attrs, assign it
    case Map.get(attrs, :role) do
      nil ->
        user

      role ->
        {:ok, user_with_role} = Ankaa.Accounts.assign_role(user, role)
        user_with_role
    end
  end

  def doctor_fixture(attrs \\ %{}) do
    user_fixture(Map.merge(%{role: "doctor"}, attrs))
  end

  def nurse_fixture(attrs \\ %{}) do
    user_fixture(Map.merge(%{role: "nurse"}, attrs))
  end

  def caresupport_fixture(attrs \\ %{}) do
    user_fixture(Map.merge(%{role: "caresupport"}, attrs))
  end

  def technical_support_fixture(attrs \\ %{}) do
    user_fixture(Map.merge(%{role: "technical_support"}, attrs))
  end

  def admin_fixture(attrs \\ %{}) do
    user_fixture(Map.merge(%{role: "admin"}, attrs))
  end

  def patient_fixture(attrs \\ %{}) do
    user = user_fixture(attrs)

    patient_attrs = %{
      name: "Test Patient",
      user_id: user.id,
      date_of_birth: Date.from_iso8601!("1980-01-01"),
      timezone: "Etc/UTC"
    }

    {:ok, _patient} = Ankaa.Patients.create_patient(patient_attrs, user)

    # Reload user to include patient association
    Ankaa.Repo.preload(user, :patient)

  end

  def device_fixture(%Ankaa.Patients.Patient{} = patient, attrs \\ %{}) do
    valid_attrs = %{
      type: "dialysis",
      model: "mock-device",
      simulation_scenario: "Normal",
      patient_id: patient.id
    }

    attrs = Map.merge(valid_attrs, attrs)

    {:ok, device} = Ankaa.Devices.create_device(attrs)
    device
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def organization_fixture(attrs \\ %{}) do
    {:ok, org} =
      attrs
      |> Enum.into(%{
        name: "Test Clinic #{System.unique_integer()}",
        type: "clinic"
      })
      |> Ankaa.Communities.create_organization()

    org
  end

  def membership_fixture(user, org, role \\ "member") do
    {:ok, membership} =
      Ankaa.Communities.add_member(user, org.id, role)
    membership
  end
end
