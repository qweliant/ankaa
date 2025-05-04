defmodule Ankaa.Patients do
  @moduledoc """
  The patient context.
  """
  import Ecto.Query

  alias Ankaa.Patients.Patient
  alias Ankaa.Patients.Device
  alias Ankaa.Repo
  alias Ankaa.Accounts.{User}

  def create_patient(attrs, user) do
    attrs =
      attrs
      |> Enum.map(fn {k, v} -> {to_string(k), v} end)
      |> Enum.into(%{})
      |> Map.put("user_id", user.id)

    %Patient{}
    |> Patient.changeset(attrs)
    |> Repo.insert()
  end

  def get_patient!(id), do: Repo.get!(Patient, id)

  def get_patient_by_user_id(user_id), do: Repo.get_by(Patient, user_id: user_id)

  def list_all_patients(%User{} = user) do
    case User.is_admin?(user) do
      true -> Repo.all(Patient)
      false -> {:error, :unauthorized}
    end
  end

  def list_all_patients(_user), do: {:error, :unauthorized}

  def change_patient(%Patient{} = patient, attrs \\ %{}) do
    Patient.changeset(patient, attrs)
  end

  def update_patient(%Patient{} = patient, attrs),
    do: patient |> Patient.changeset(attrs) |> Repo.update()

  def delete_patient(%Patient{} = patient), do: Repo.delete(patient)

  def create_device(attrs) do
    %Device{}
    |> Device.changeset(attrs)
    |> Repo.insert()
  end

  def get_device!(id), do: Repo.get!(Device, id)

  def list_devices_for_patient(patient_id),
    do: Repo.all(from(d in Device, where: d.patient_id == ^patient_id))

  def change_device(%Device{} = device, attrs \\ %{}) do
    Device.changeset(device, attrs)
  end

  def update_device(%Device{} = device, attrs),
    do: device |> Device.changeset(attrs) |> Repo.update()

  def delete_device(%Device{} = device), do: Repo.delete(device)
end
