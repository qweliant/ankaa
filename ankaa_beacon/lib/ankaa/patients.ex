defmodule Ankaa.Patients do
  @moduledoc """
  The patient context
  """
  import Ecto.Query

  alias Ankaa.Patients.{Patient, Device, PatientAssociation}
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

  # Patient association functions

  @doc """
  list all the patients a doctor, nurse, or patient may be associated to
  """
  def list_patients(%User{} = user) do
    cond do
      User.is_admin?(user) ->
        {:ok, Repo.all(Patient)}

      User.is_doctor?(user) or User.is_nurse?(user) ->
        {:ok, list_care_provider_patients(user)}

      User.is_patient?(user) ->
        # Get the patient record for this user first
        patient = get_patient_by_user_id(user.id)
        if patient, do: {:ok, list_peer_patients(patient)}, else: {:error, :patient_not_found}

      true ->
        {:error, :unauthorized}
    end
  end

  def list_patients(_user), do: {:error, :unauthorized}

  @doc """
  Search patients (available to doctors, nurses, and patients for peer support)
  """
  def search_patients(%User{} = user, search_terms) do
    base_query = from(p in Patient)

    query =
      case search_terms do
        %{name: name} ->
          from(p in base_query, where: ilike(p.name, ^"%#{name}%"))

        %{external_id: id} ->
          from(p in base_query, where: p.external_id == ^id)

        _ ->
          base_query
      end

    with {:ok, patients} <- list_patients(user) do
      patient_ids = Enum.map(patients, & &1.id)
      {:ok, Repo.all(from(p in query, where: p.id in ^patient_ids))}
    end
  end

  @doc """
  Creates a patient association if the user is a doctor or nurse.

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
        # Example business rule
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
  """
  def create_peer_association(%User{} = patient_user, %Patient{} = peer_patient) do
    if User.is_patient?(patient_user) do
      # First get the patient record for this user
      with %Patient{} = patient <- get_patient_by_user_id(patient_user.id) do
        %PatientAssociation{}
        |> PatientAssociation.changeset(%{
          user_id: patient_user.id,
          patient_id: peer_patient.id,
          relationship: "peer_support",
          # Peers typically can't send alerts
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

  defp list_care_provider_patients(user) do
    # Query PatientAssociation and join with Patient to get actual patient records
    query =
      from(pa in PatientAssociation,
        join: p in Patient,
        on: pa.patient_id == p.id,
        where: pa.user_id == ^user.id,
        select: p
      )

    Repo.all(query)
  end

  defp list_peer_patients(patient) do
    # Patients can see other patients in their support groups
    # Implement your business logic here - example:
    Patient
    # Don't show themselves
    |> where([p], p.id != ^patient.id)
    |> Repo.all()

    # Alternative implementation might use patient associations:
    # query =
    #   from pa in PatientAssociation,
    #     join: p in Patient, on: pa.patient_id == p.id,
    #     where: pa.user_id == ^patient_user.id and pa.relationship == "peer_support",
    #     select: p
    # Repo.all(query)
  end
end
