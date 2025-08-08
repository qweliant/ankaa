defmodule Ankaa.Sessions do
  import Ecto.Query, warn: false
  alias Ankaa.Repo
  alias Ankaa.Sessions.Session

  @doc """
  Returns a list of all sessions for a patient, newest first.
  """
  def list_sessions_for_patient(patient_id) do
    Repo.all(
      from(s in Session,
        where: s.patient_id == ^patient_id,
        order_by: [desc: s.start_time]
      )
    )
  end

  @doc """
  Finds the current "ongoing" session for a patient.
  Returns nil if no session is active.
  """
  def get_active_session_for_patient(patient_id) do
    from(s in Session,
      where: s.patient_id == ^patient_id and s.status == "ongoing"
    )
    |> Repo.one()
  end

  def get_session!(id), do: Repo.get!(Session, id)

  @doc """
  Gets the most recent session for a patient, regardless of status.
  Returns a single session or nil.
  """
  def get_latest_session_for_patient(%Ankaa.Patients.Patient{} = patient) do
    from(s in Session,
      where: s.patient_id == ^patient.id,
      order_by: [desc: s.start_time],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Creates a new session. This is used when a patient clicks "Start Session".
  """
  def create_session(attrs \\ %{}) do
    %Session{}
    |> Session.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Ends an ongoing session with default values.
  """
  def end_session(%Session{} = session) do
    end_session(session, %{})
  end

  @doc """
  Ends an ongoing session, setting its end_time and status.
  Allows for overriding default end attributes.
  """
  def end_session(%Session{} = session, attrs \\ %{}) do
    end_attrs =
      Map.merge(
        %{
          status: "completed",
          end_time: DateTime.utc_now()
        },
        attrs
      )

    update_session(session, end_attrs)
  end

  def update_session(%Session{} = session, attrs) do
    session
    |> Session.changeset(attrs)
    |> Repo.update()
  end

  def delete_session(%Session{} = session) do
    Repo.delete(session)
  end
end
