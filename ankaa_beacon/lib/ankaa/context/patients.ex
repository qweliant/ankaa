defmodule Ankaa.Patients do
  @moduledoc """
  The Patients context.

  This context handles all operations related to patients, devices, and care network.
  """
  import Ecto.Query

  alias Ankaa.Repo
  alias Ankaa.Patients.{Patient, CareNetwork}
  alias Ankaa.Accounts.User
  alias Ankaa.Notifications.Invite
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
      User.admin?(user) ->
        {:ok, list_patients()}

      User.doctor?(user) or User.nurse?(user) ->
        {:ok, list_care_provider_patients(user)}

      User.patient?(user) ->
        case get_patient_by_user_id(user.id) do
          %Patient{} = patient -> {:ok, list_peer_patients(patient)}
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
    default_permissions = ["receive_alerts"]
    if User.doctor?(user) || User.nurse?(user) || User.caresupport?(user) do
      %CareNetwork{}
      |> CareNetwork.changeset(%{
        user_id: user.id,
        patient_id: patient.id,
        relationship: relationship,
        permissions: default_permissions
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
    default_permissions = ["receive_alerts"]
    # Get the User struct for the second patient
    user2 = Repo.get!(User, peer_patient.user_id)

    # Use a transaction to ensure both or neither are created
    Repo.transaction(fn ->
      # Create link: User 2 is a peer for Patient 1
      %CareNetwork{}
      |> CareNetwork.changeset(%{
        user_id: user2.id,
        patient_id: patient_user.patient.id,
        relationship: "peer_support",
        permissions: default_permissions
      })
      |> Repo.insert!()

      # Create reciprocal link: User 1 is a peer for Patient 2
      %CareNetwork{}
      |> CareNetwork.changeset(%{
        user_id: patient_user.id,
        patient_id: peer_patient.id,
        relationship: "peer_support",
        permissions: default_permissions
      })
      |> Repo.insert!()
    end)
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

  @doc """
  Gets a single care network member by their ID.
  """
  def get_care_network_member!(id) do
    Repo.get!(CareNetwork, id)
    |> Repo.preload(:user)
  end

  @doc """
  Updates a care network member's attributes, such as their permissions.
  """
  def update_care_network_member(%CareNetwork{} = member, attrs) do
    member
    |> CareNetwork.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Removes a member from a patient's care network.
  """
  def remove_care_network_member(%CareNetwork{} = member) do
    Repo.delete(member)
  end

  @doc """
  Gets the full CareNetwork structs with user data for management purposes.
  """
  def list_care_network_members(patient_id) do
    from(cn in CareNetwork,
      where: cn.patient_id == ^patient_id,
      preload: [:user]
    )
    |> Repo.all()
  end

  @doc """
  Checks if a given user is authorized to manage a patient's care network.
  """
  def can_manage_network?(%User{} = user, %Patient{} = patient) do
    # patient can always manage their own network.
    is_the_patient = user.id == patient.user_id

    if is_the_patient do
      true
    else
      # check if the user is a member with the correct permission.
      case Repo.get_by(CareNetwork, user_id: user.id, patient_id: patient.id) do
        nil ->
          # Not a member of the network.
          false

        %CareNetwork{permissions: permissions} ->
          # is a member; check if they have the "manage_network" permission.
          "manage_network" in permissions
      end
    end
  end

  # Private helpers
  defp list_care_provider_patients(user) do
    CareNetwork
    |> join(:inner, [pa], p in Patient, on: pa.patient_id == p.id)
    |> where([pa, _], pa.user_id == ^user.id)
    |> select([_, p], p)
    |> Repo.all()
  end

  defp list_peer_patients(%Patient{} = patient) do
    peer_user_ids_query =
      from(cn in CareNetwork,
        where: cn.patient_id == ^patient.id and cn.relationship == "peer_support",
        select: cn.user_id
      )
    from(p in Patient,
      where: p.user_id in subquery(peer_user_ids_query)
    )
    |> Repo.all()
  end

  defp list_accepted_members(%Patient{} = patient) do
    query =
      from(cn in CareNetwork,
        where: cn.patient_id == ^patient.id,
        join: u in assoc(cn, :user),
        # Select the raw structs we need
        select: {cn, u}
      )

    Repo.all(query)
    |> Enum.map(fn {care_network, user} ->
      # Safely build the full name, handling potential nil values
      full_name =
        [user.first_name, user.last_name]
        |> Enum.reject(&is_nil/1)
        |> Enum.join(" ")

      # If the name is blank after joining, fall back to the email
      display_name = if full_name == "", do: user.email, else: full_name

      %{
        id: care_network.id,
        name: display_name,
        role: care_network.relationship,
        email: user.email,
        status: "active"
      }
    end)
  end

  defp list_pending_members(%Patient{} = patient) do
    from(i in Invite,
          where: i.patient_id == ^patient.id and i.status == "pending",
          select: i
        )
        |> Repo.all()
        |> Enum.map(fn invite ->
          %{
            id: invite.id,
            name: "Invitation to #{invite.invitee_email}",
            role: invite.invitee_role,
            status: "pending"
          }
        end)
  end
end
