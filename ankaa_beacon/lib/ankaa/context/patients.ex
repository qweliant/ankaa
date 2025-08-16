defmodule Ankaa.Patients do
  @moduledoc """
  The Patients context.

  This context handles all operations related to patients, devices, and care network.
  """
  import Ecto.Query

  alias Ankaa.Repo
  alias Ankaa.Patients.{Patient, CareNetwork}
  alias Ankaa.Accounts.User
  alias Ankaa.Invites.Invite
  alias Ankaa.Sessions

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

  # Patient Association functions

  @doc """
  Creates a patient association for healthcare providers.

  ## Examples

      iex> create_patient_association(doctor, patient, "doctor")
      {:ok, %CareNetwork{}}

      iex> create_patient_association(patient_user, other_patient, "peer")
      {:error, :unauthorized_role}
  """
  def create_patient_association(%User{} = user, %Patient{} = patient, relationship) do
    if User.is_doctor?(user) || User.is_nurse?(user) || User.is_caresupport?(user) do
      %CareNetwork{}
      |> CareNetwork.changeset(%{
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
      {:ok, %CareNetwork{}}

      iex> create_peer_association(non_patient_user, other_patient)
      {:error, :not_a_patient}
  """
  def create_peer_association(%User{} = patient_user, %Patient{} = peer_patient) do
    if User.is_patient?(patient_user) do
      with %Patient{} = _patient <- get_patient_by_user_id(patient_user.id) do
        %CareNetwork{}
        |> CareNetwork.changeset(%{
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

  @doc """
  Gets all patient IDs associated with a given care provider user ID.

  ## Examples

      iex> get_patient_ids_for_care_provider("user_id_123")
      ["patient_id_abc", "patient_id_def"]
  """
  def get_patient_ids_for_care_network(user_id) do
    from(cn in CareNetwork,
      where: cn.user_id == ^user_id,
      select: cn.patient_id
    )
    |> Repo.all()
  end

  @doc """
  Gets the full care network for a patient, including active and pending members.
  """
  def get_care_network_for_patient(%Patient{} = patient) do
    accepted_members = list_accepted_members(patient)
    pending_members = list_pending_members(patient)

    accepted_members ++ pending_members
  end

  @doc """
  Gets all Patient records associated with a given user, formatted for display.
  """
  def list_patients_for_any_role(%User{} = user) do
    query =
      from(cn in CareNetwork,
        where: cn.user_id == ^user.id,
        join: p in Patient,
        on: cn.patient_id == p.id,
        select: %{patient: p, care_link: cn}
      )

    Repo.all(query)
    |> Enum.map(fn %{patient: p, care_link: cn} ->
      latest_session = Sessions.get_latest_session_for_patient(p)

      {status, last_session_start} =
        case latest_session do
          %Ankaa.Sessions.Session{status: s, start_time: st} -> {String.capitalize(s), st}
          nil -> {"No Sessions", nil}
        end

      %{
        id: p.id,
        name: p.name,
        relationship: cn.relationship |> String.capitalize(),
        status: status,
        last_session: last_session_start,
        # Adding placeholders for data that doesn't exist in the DB yet
        # Placeholder: in 2 days
        next_session: Date.add(Date.utc_today(), 2),
        # Placeholder
        alerts: 0
      }
    end)
  end

  @doc """
  Gets the relationship between a provider/supporter and a patient.
  """
  def get_relationship(%User{} = provider_user, %Patient{} = patient) do
    care_link = Repo.get_by(CareNetwork, user_id: provider_user.id, patient_id: patient.id)
    (care_link && care_link.relationship) || "Unknown"
  end

  # Private helpers

  defp list_care_provider_patients(user) do
    CareNetwork
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

  defp list_accepted_members(%Patient{} = patient) do
    query =
      from(cn in CareNetwork,
        where: cn.patient_id == ^patient.id,
        join: u in User,
        on: cn.user_id == u.id,
        # Select the fields we need to build the map
        select: %{
          id: u.id,
          # You can change this to `u.name` if you have a name field on your User schema
          name: u.email,
          role: cn.relationship,
          email: u.email,
          status: "active"
        }
      )

    Repo.all(query)
  end

  defp list_pending_members(%Patient{} = patient) do
    query =
      from(i in Invite,
        where: i.patient_id == ^patient.id and i.status == "pending",
        select: %{
          id: i.id,
          name: "Pending Invitation",
          role: i.invitee_role,
          email: i.invitee_email,
          status: "pending"
        }
      )

    Repo.all(query)
  end
end
