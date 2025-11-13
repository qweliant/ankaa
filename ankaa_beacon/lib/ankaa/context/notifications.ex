defmodule Ankaa.Notifications do
  @moduledoc """
  The Notifications context.
  """
  import Ecto.Query

  alias Ankaa.Repo
  alias Ankaa.Notifications.Notification

  require Logger

  @doc """
  Creates a notification.
  """
  def create_notification(attrs) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Finds a specific notification for a user and marks it as dismissed.
  """
  def dismiss_notification(user_id, alert_id) do
    from(n in Notification,
      where: n.user_id == ^user_id and n.alert_id == ^alert_id
    )
    |> Repo.update_all(set: [status: "dismissed"])
  end

  @doc """
  dismisses notifications for all users
  """
  def dismiss_all_notifications_for_alert(alert_id) do
    from(n in Notification,
      where:
        n.notifiable_id == ^alert_id and
          n.notifiable_type == "Alert"
    )
    |> Repo.update_all(set: [status: "dismissed"])
  end
end
