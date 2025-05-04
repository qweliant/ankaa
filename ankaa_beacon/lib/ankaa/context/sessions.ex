defmodule Ankaa.Sessions do
  import Ecto.Query, warn: false
  alias Ankaa.Repo
  alias Ankaa.Sessions.Session

  def list_sessions_for_patient(patient_id) do
    Repo.all(
      from(s in Session,
        where: s.patient_id == ^patient_id,
        order_by: [desc: s.date]
      )
    )
  end

  def get_session!(id), do: Repo.get!(Session, id)

  def create_session(attrs \\ %{}) do
    %Session{}
    |> Session.changeset(attrs)
    |> Repo.insert()
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
