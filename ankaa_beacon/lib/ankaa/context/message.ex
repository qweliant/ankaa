defmodule Ankaa.Message do
  @moduledoc """
  The Messages context.
  """
  alias Ankaa.Repo
  import Ecto.Query
  alias Ankaa.Notifications.Messages

  @doc "Lists all messages for a given patient."
  def list_messages_for_patient(patient_id) do
    from(m in Messages,
      where: m.patient_id == ^patient_id,
      order_by: [desc: m.inserted_at]
    )
    |> Repo.all()
  end
end
