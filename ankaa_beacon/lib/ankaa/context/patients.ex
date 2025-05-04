defmodule Ankaa.Patients do
  @moduledoc """
  The Patients context.

  This context handles all operations related to patients, devices, and patient associations.
  """
  import Ecto.Query

  alias Ankaa.Repo
  alias Ankaa.Patients.{Patient, Device, PatientAssociation}
  alias Ankaa.Accounts.User

  @doc """
  Returns the list of patients.

  ## Examples

      iex> list_patients()
      [%Patient{}, ...]

  """
  def list_patients do
    Repo.all(Patient)
  end

  @doc """
  Lists patients a user can access based on their role.

  Returns `{:ok, [%Patient{}]}` or `{:error, reason}`.

  ## Examples

      iex> list_patients_for_user(%User{role: "doctor"})
      {:ok, [%Patient{}, ...]}

      iex> list_patients_for_user(%User{role: "patient"})
      {:ok, [%Patient{}, ...]}

  """
  def list_patients_for_user(%User{} = user) do
    cond do
      User.is_admin?(user) ->
        {:ok, list_patients()}

      User.is_doctor?(user) or User.is_nurse?(user) ->
        {:ok, list_care_provider_patients(user)}

      User.is_patient?(user) ->
        with %Patient{} = patient <- get_patient_by_user_id(user.id) do
          {:ok, list_peer_patients(patient)}
        else
          nil -> {:error, :patient_not_found}
        end

      true ->
        {:error, :unauthorized}
    end
  end

  @doc """
  Gets a single patient.

  Raises `Ecto.NoResultsError` if the Patient does not exist.

  ## Examples

      iex> get_patient!(123)
      %Patient{}

      iex> get_patient!(456)
      ** (Ecto.NoResultsError)

  """
  def get_patient!(id), do: Repo.get!(Patient, id)

  @doc """
  Gets a patient by user_id.

  ## Examples

      iex> get_patient_by_user_id(123)
      %Patient{}

      iex> get_patient_by_user_id(456)
      nil

  """
  def get_patient_by_user_id(user_id), do: Repo.get_by(Patient, user_id: user_id)

  @doc """
  Creates a patient.

  ## Examples

      iex> create_patient(%{field: value}, %User{})
      {:ok, %Patient{}}

      iex> create_patient(%{field: bad_value}, %User{})
      {:error, %Ecto.Changeset{}}

  """
  def create_patient(attrs, %User{} = user) do
    attrs =
      attrs
      |> Map.new(fn {k, v} -> {to_string(k), v} end)
      |> Map.put("user_id", user.id)

    %Patient{}
    |> Patient.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a patient.

  ## Examples

      iex> update_patient(patient, %{field: new_value})
      {:ok, %Patient{}}

      iex> update_patient(patient, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_patient(%Patient{} = patient, attrs) do
    patient
    |> Patient.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a patient.

  ## Examples

      iex> delete_patient(patient)
      {:ok, %Patient{}}

      iex> delete_patient(patient)
      {:error, %Ecto.Changeset{}}

  """
  def delete_patient(%Patient{} = patient) do
    Repo.delete(patient)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking patient changes.

  ## Examples

      iex> change_patient(patient)
      %Ecto.Changeset{data: %Patient{}}

  """
  def change_patient(%Patient{} = patient, attrs \\ %{}) do
    Patient.changeset(patient, attrs)
  end

  @doc """
  Searches patients by name or external_id.
  Only returns patients the user has access to.

  ## Examples

      iex> search_patients(user, %{name: "John"})
      {:ok, [%Patient{name: "John Doe"}, ...]}

  """
  def search_patients(%User{} = user, search_terms) do
    base_query = from(p in Patient)

    query =
      case search_terms do
        %{name: name} when is_binary(name) and name != "" ->
          from(p in base_query, where: ilike(p.name, ^"%#{name}%"))

        %{external_id: id} when is_binary(id) or is_integer(id) ->
          from(p in base_query, where: p.external_id == ^id)

        _ ->
          base_query
      end

    with {:ok, patients} <- list_patients_for_user(user) do
      patient_ids = Enum.map(patients, & &1.id)
      {:ok, Repo.all(from(p in query, where: p.id in ^patient_ids))}
    end
  end

  # Device functions

  @doc """
  Returns the list of devices for a patient.

  ## Examples

      iex> list_devices_for_patient(123)
      [%Device{}, ...]

  """
  def list_devices_for_patient(patient_id) do
    Device
    |> where(patient_id: ^patient_id)
    |> Repo.all()
  end

  @doc """
  Gets a single device.

  Raises `Ecto.NoResultsError` if the Device does not exist.

  ## Examples

      iex> get_device!(123)
      %Device{}

      iex> get_device!(456)
      ** (Ecto.NoResultsError)

  """
  def get_device!(id), do: Repo.get!(Device, id)

  @doc """
  Creates a device.

  ## Examples

      iex> create_device(%{field: value})
      {:ok, %Device{}}

      iex> create_device(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_device(attrs) do
    %Device{}
    |> Device.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a device.

  ## Examples

      iex> update_device(device, %{field: new_value})
      {:ok, %Device{}}

      iex> update_device(device, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_device(%Device{} = device, attrs) do
    device
    |> Device.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a device.

  ## Examples

      iex> delete_device(device)
      {:ok, %Device{}}

      iex> delete_device(device)
      {:error, %Ecto.Changeset{}}

  """
  def delete_device(%Device{} = device) do
    Repo.delete(device)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking device changes.

  ## Examples

      iex> change_device(device)
      %Ecto.Changeset{data: %Device{}}

  """
  def change_device(%Device{} = device, attrs \\ %{}) do
    Device.changeset(device, attrs)
  end

  # Patient Association functions

  @doc """
  Creates a patient association for healthcare providers.

  ## Examples

      iex> create_patient_association(doctor, patient, "doctor")
      {:ok, %PatientAssociation{}}

      iex> create_patient_association(patient_user, other_patient, "peer")
      {:error, :unauthorized_role}
  """
  def create_patient_association(%User{} = user, %Patient{} = patient, relationship) do
    if User.is_doctor?(user) || User.is_nurse?(user) || User.is_caresupport?(user) do
      %PatientAssociation{}
      |> PatientAssociation.changeset(%{
        user_id: user.id,
        patient_id: patient.id,
        relationship: relationship,
        can_alert: relationship in ["doctor", "nurse", "caresupport"]
      })
      |> Repo.insert()
    else
      {:error, :unauthorized_role}
    end
  end

  @doc """
  Creates a peer support association between patients.

  ## Examples

      iex> create_peer_association(patient_user, other_patient)
      {:ok, %PatientAssociation{}}

      iex> create_peer_association(non_patient_user, other_patient)
      {:error, :not_a_patient}
  """
  def create_peer_association(%User{} = patient_user, %Patient{} = peer_patient) do
    if User.is_patient?(patient_user) do
      with %Patient{} = patient <- get_patient_by_user_id(patient_user.id) do
        %PatientAssociation{}
        |> PatientAssociation.changeset(%{
          user_id: patient_user.id,
          patient_id: peer_patient.id,
          relationship: "peer_support",
          can_alert: false
        })
        |> Repo.insert()
      else
        nil -> {:error, :patient_not_found}
      end
    else
      {:error, :not_a_patient}
    end
  end

  # Private helpers

  defp list_care_provider_patients(user) do
    PatientAssociation
    |> join(:inner, [pa], p in Patient, on: pa.patient_id == p.id)
    |> where([pa, _], pa.user_id == ^user.id)
    |> select([_, p], p)
    |> Repo.all()
  end

  defp list_peer_patients(patient) do
    Patient
    |> where([p], p.id != ^patient.id)
    |> Repo.all()
  end
end
