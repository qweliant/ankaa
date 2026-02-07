defmodule Ankaa.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ankaa.Accounts` context.
  """
  alias Ankaa.Accounts
  alias Ankaa.Patients
  alias Ankaa.Communities

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password(),
      first_name: "Test",
      last_name: "User"
    })
  end

  def valid_user_password, do: "hello world!123"

  @doc """
  Generate a unique user email.
  """
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  defp create_user(attrs) do
    {_legacy, valid_attrs} = Map.pop(attrs, :role)

    clean_attrs =
      Enum.into(valid_attrs, %{
        email: unique_user_email(),
        password: valid_user_password(),
        first_name: "Test",
        last_name: "User"
      })

    {:ok, user} = Accounts.register_user(clean_attrs)
    user
  end

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    user = create_user(attrs)
    user
  end

  def patient_fixture(attrs \\ %{}) do
    user = create_user(attrs)

    hub_attrs = %{
      name: "Test Patient",
      date_of_birth: ~D[1980-01-01],
      timezone: "Etc/UTC",
      relationship: "Patient",
      role: :patient
    }

    {:ok, %{patient: patient, membership: membership}} =
      Patients.create_patient_hub(user, hub_attrs)

    user = Ankaa.Repo.preload(user, :patient)

    %{
      user: user,
      membership: membership,
      patient: patient
    }
  end

  def doctor_fixture(attrs \\ %{}) do
    care_member_fixture(:doctor, attrs)
  end

  def nurse_fixture(attrs \\ %{}) do
    care_member_fixture(:nurse, attrs)
  end

  def caresupport_fixture(attrs \\ %{}) do
    care_member_fixture(:caresupport, attrs)
  end

  def tech_fixture(attrs \\ %{}) do
    care_member_fixture(:tech, attrs)
  end

  def admin_fixture(attrs \\ %{}) do
    user = user_fixture(attrs)
    user
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

  defp care_member_fixture(role_atom, attrs) do
    user = create_user(attrs)

    patient_attrs = %{
      name: "Patient of #{user.first_name}",
      date_of_birth: ~D[1990-01-01],
      relationship: "Patient",
      role: :patient # Atom
    }

    {:ok, %{patient: patient}} = Patients.create_patient_hub(user, patient_attrs)

    # Update the automatically created link to match the requested Role
    # (create_patient_hub defaults creator to :owner, we want :doctor/:nurse)
    membership =
      Ankaa.Repo.get_by!(Ankaa.Patients.CareNetwork, user_id: user.id, patient_id: patient.id)
      |> Ankaa.Patients.CareNetwork.changeset(%{
        role: role_atom,
        permission: default_permission_for(role_atom),
        relationship: Atom.to_string(role_atom) |> String.capitalize()
      })
      |> Ankaa.Repo.update!()

    %{
      user: user,
      membership: membership,
      patient: patient
    }
  end

  defp default_permission_for(:doctor), do: :contributor
  defp default_permission_for(:nurse), do: :contributor
  defp default_permission_for(:caresupport), do: :viewer
  defp default_permission_for(_), do: :viewer
end
