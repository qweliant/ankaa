defmodule Ankaa.Patients do
  @moduledoc """
  The Patients context.

  This context handles all operations related to patients, devices, and care network.
  """
  import Ecto.Query

  require Logger
  alias Ankaa.Repo
  alias Ankaa.Patients.{Patient, CareNetwork, MoodTracker, TreatmentPlan}
  alias Ankaa.Accounts.User
  alias Ankaa.Notifications.Invite
  alias Ankaa.Sessions
  alias Ankaa.Community.OrganizationMembership

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
      user.role == "admin" ->
        {:ok, list_patients()}

      user.role in ["doctor", "nurse", "clinic_technician", "social_worker"] ->
        patients =
          list_care_provider_patients(user)
          |> Repo.preload([:user, :devices])

        {:ok, patients}

      patient_rec = get_patient_by_user_id(user.id) ->
        if patient_rec do
          patients =
            list_peer_patients(patient_rec)
            |> Repo.preload([:user, :devices])

          {:ok, patients}
        else
          {:error, :unauthorized}
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
  def search_patients(%User{} = user, params) do
    case list_patients_for_user(user) do
      {:ok, allowed_patients} ->
        # Filter the allowed list in memory or compose a new query
        # Since we already fetched them, let's filter in memory for simplicity
        # (or better: refactor to use composable Ecto queries)

        search_term = Map.get(params, :name)

        results =
          if is_nil(search_term) or search_term == "" do
            allowed_patients
          else
            Enum.filter(allowed_patients, fn p ->
              String.contains?(String.downcase(p.name), String.downcase(search_term))
            end)
          end

        {:ok, results}

      error ->
        error
    end
  end

  @doc """
  Retrieves the MoodTracker entry for the given patient for the current day.
  """
  def get_mood_entry_for_today(patient_id) do
    current_date = Date.utc_today()
    {:ok, start_of_day} = NaiveDateTime.new(current_date, ~T[00:00:00])
    tomorrow_date = Date.add(current_date, 1)
    {:ok, end_of_day} = NaiveDateTime.new(tomorrow_date, ~T[00:00:00])

    from(m in MoodTracker,
      where: m.patient_id == ^patient_id,
      where: m.inserted_at >= ^start_of_day and m.inserted_at < ^end_of_day,
      order_by: [desc: m.inserted_at],
      limit: 1
    )
    |> Ankaa.Repo.one()
  end

  @doc """
  Returns a changeset for creating a new MoodTracker entry.
  """
  def create_mood_tracker_changeset(%Patient{} = patient) do
    %MoodTracker{}
    |> MoodTracker.changeset(%{mood: "Okay", patient_id: patient.id})
  end

  @doc """
  Saves a new MoodTracker entry.
  """
  def save_mood_tracker_entry(%Patient{} = patient, params) do
    params = Map.put(params, "patient_id", patient.id)

    %MoodTracker{}
    |> MoodTracker.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Gets the treatment plan for a specific patient.
  Returns nil if no plan exists.
  """
  def get_treatment_plan(patient_id) do
    Repo.get_by(TreatmentPlan, patient_id: patient_id)
    |> Repo.preload(:prescribed_by)
  end

  @doc """
  Updates an existing treatment plan or creates a new one if it doesn't exist.
  Tracks which user made the change.
  """
  def update_treatment_plan(%TreatmentPlan{} = plan, attrs, user) do
    plan
    |> TreatmentPlan.changeset(attrs)
    |> Ecto.Changeset.put_change(:prescribed_by_id, user.id)
    |> Repo.insert_or_update()
  end

  @doc """
  Helper for the UI: Returns a changeset for the plan.
  """
  def change_treatment_plan(%TreatmentPlan{} = plan, attrs \\ %{}) do
    TreatmentPlan.changeset(plan, attrs)
  end

  # Patient Association functions

  @doc """
  Creates a patient association for care network.

  ## Arguments
  - user: The provider/caregiver
  - patient: The patient hub
  - relationship: Display label ("Doctor", "Mom")
  - access_role: The permission level (:admin, :contributor, :viewer). Defaults to :viewer.

  ## Examples

      iex> create_patient_association(doctor, patient, "doctor")
      {:ok, %CareNetwork{}}

      iex> create_patient_association(patient_user, other_patient, "peer")
      {:error, :unauthorized_role}
  """
  def create_patient_association(
        %User{} = user_struct,
        %Patient{} = patient,
        relationship,
        access_role \\ :viewer
      ) do
    user = Ankaa.Accounts.get_user!(user_struct.id)

    is_authorized =
      User.doctor?(user) ||
        User.nurse?(user) ||
        User.clinic_technician?(user) ||
        User.social_worker?(user) ||
        User.community_coordinator?(user) ||
        User.caresupport?(user) ||
        User.admin?(user)

    if is_authorized do
      %CareNetwork{}
      |> CareNetwork.changeset(%{
        user_id: user.id,
        patient_id: patient.id,
        relationship: relationship,
        role: access_role
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
        role: :viewer
      })
      |> Repo.insert!()

      # Create reciprocal link: User 1 is a peer for Patient 2
      %CareNetwork{}
      |> CareNetwork.changeset(%{
        user_id: patient_user.id,
        patient_id: peer_patient.id,
        relationship: "peer_support",
        role: :viewer
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
  Returns a changeset for updating an existing MoodTracker entry.
  """
  def get_mood_tracker_changeset(%MoodTracker{} = mood_tracker) do
    MoodTracker.changeset(mood_tracker, %{})
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
        next_session: Date.add(Date.utc_today(), 2),
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
      end
    end
  end

  @doc """
  Gets the specific CareNetwork entry for a given user and patient.
  """
  def get_care_network_entry(user_id, patient_id) do
    Repo.get_by(CareNetwork, user_id: user_id, patient_id: patient_id)
  end

  @doc """
  Tries to find a CareNetwork entry, or creates one if it doesn't exist.
  """
  def get_or_create_care_network_entry(user_id, patient_id) do
    case get_care_network_entry(user_id, patient_id) do
      nil ->
        # Doesn't exist, let's create a new one
        attrs = %{
          user_id: user_id,
          patient_id: patient_id,
          relationship: "Care Support"
        }

        %CareNetwork{}
        |> CareNetwork.changeset(attrs)
        |> Repo.insert()

      entry ->
        {:ok, entry}
    end
  end

  @doc """
  Updates the fridge card notes for a specific CareNetwork entry.
  """
  def update_fridge_card_notes(%CareNetwork{} = entry, notes) do
    entry
    |> CareNetwork.changeset(%{fridge_card_notes: notes})
    |> Repo.update()
  end

  @doc """
  Lists available colleagues in the same organization who are not yet assigned to the patient's care network.

  ## Examples

      iex> list_available_colleagues(doctor_user, patient_id)
      [%User{}, ...]

  """
  def list_available_colleagues(%User{} = doctor, patient_id) do
    doctor_org_ids_query =
      from(m in OrganizationMembership,
        where: m.user_id == ^doctor.id,
        select: m.organization_id
      )

    assigned_user_ids_query =
      from(c in CareNetwork,
        where: c.patient_id == ^patient_id,
        select: c.user_id
      )

    from(u in User,
      join: m in OrganizationMembership,
      on: m.user_id == u.id,
      where: m.organization_id in subquery(doctor_org_ids_query),
      where: u.id != ^doctor.id,
      where: u.id not in subquery(assigned_user_ids_query),
      where: u.role in ["doctor", "nurse", "clinic_technician", "social_worker"],
      distinct: u.id,
      order_by: [asc: u.last_name]
    )
    |> Repo.all()
  end

  @doc """
  Adds an existing medical professional to a patient's care network by email.
  """
  def add_care_team_member_by_email(patient_id, email) do
    case Ankaa.Accounts.get_user_by_email(email) do
      %User{} = user -> add_care_team_member(patient_id, user)
      nil -> {:error, :not_found}
    end
  end

  @doc """
  Lists all care network members for a patient who are NOT the patient themselves.
  """
  def list_care_team(patient_id) do
    from(c in CareNetwork,
      join: u in assoc(c, :user),
      where: c.patient_id == ^patient_id,
      # Exclude the patient record itself
      where: u.role != "patient",
      preload: [user: u]
    )
    |> Repo.all()
  end

  @doc """
  Removes a member from the care network by the association ID.
  """
  def delete_care_network_member(%CareNetwork{} = member) do
    Repo.delete(member)
  end

  @doc """
  Adds an existing medical professional to a patient's care network by User ID.
  (Used by the 'Add Colleague' dropdown)
  """
  def add_care_team_member_by_id(patient_id, user_id) do
    case Repo.get(User, user_id) do
      %User{} = user -> add_care_team_member(patient_id, user)
      nil -> {:error, :not_found}
    end
  end

  # Mock function to generate social flags for the UI
  # In the future, this would query a `social_assessments` table
  def get_social_status(patient) do
    case :erlang.phash2(patient.id, 3) do
      0 ->
        %{
          risk: "high",
          flags: ["Housing Instability", "Insurance Expiring"],
          assessment_due: true
        }

      1 ->
        %{risk: "medium", flags: ["Caregiver Burnout"], assessment_due: false}

      _ ->
        %{risk: "low", flags: [], assessment_due: false}
    end
  end

  # lib/ankaa/patients.ex

  @doc """
  Returns a list of patients associated with the given user via the care network.
  Used for Social Workers, Community Coordinators, and Technicians to see their caseload.
  """
  def list_assigned_patients(%Ankaa.Accounts.User{} = user) do
    from(p in Patient,
      join: c in assoc(p, :care_network),
      where: c.user_id == ^user.id,
      preload: [:user],
      order_by: [asc: p.name]
    )
    |> Repo.all()
  end

  defp list_care_provider_patients(user) do
    CareNetwork
    |> join(:inner, [cn], p in Patient, on: cn.patient_id == p.id)
    |> where([cn, _], cn.user_id == ^user.id)
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

  defp add_care_team_member(patient_id, user) do
    if user.role in ["doctor", "nurse", "clinic_technician", "social_worker"] do
      role =
        case user.role do
          "clinic_technician" -> :viewer
          "social_worker" -> :viewer
          _ -> :contributor
        end

      %CareNetwork{}
      |> CareNetwork.changeset(%{
        user_id: user.id,
        patient_id: patient_id,
        relationship: String.capitalize(user.role),
        role: role
      })
      |> Repo.insert()
    else
      {:error, "User exists but is not a medical professional."}
    end
  end
end
