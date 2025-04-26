defmodule Ankaa.Notifications.Recipient do
  @moduledoc """
  Schema and functions for alert recipients.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "alert_recipients" do
    field(:role, Ecto.Enum, values: [:caregiver, :doctor, :support_agent, :emergency_contact])
    field(:channels, {:array, Ecto.Enum}, values: [:sms, :email, :app, :voice])

    belongs_to(:user, Ankaa.Accounts.User)
    belongs_to(:patient, Ankaa.Accounts.User, references: :id)

    timestamps()
  end

  # Changeset and query functions

  @doc """
  Gets all recipients for a patient by role.
  """
  @spec get_recipients_by_role(User.t(), atom()) :: [Recipient.t()]
  def get_recipients_by_role(_patient, _role) do
    # Logic to fetch recipients by role
  end
end
