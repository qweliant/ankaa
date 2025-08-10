defmodule Ankaa.Notifications do
  import Ecto.Query

  alias Ankaa.Repo
  alias Ankaa.Notifications.Notification

  @doc """
  Finds a specific notification for a user and marks it as dismissed.
  """
  def dismiss_notification(user_id, alert_id) do
    from(n in Notification,
      where: n.user_id == ^user_id and n.alert_id == ^alert_id
    )
    |> Repo.update_all(set: [status: "dismissed"])
  end
end
