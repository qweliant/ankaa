defmodule Ankaa.Notifications.Alert do
  @moduledoc """
  Schema and functions for alerts.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "alerts" do
    field(:title, :string)
    field(:message, :string)
    field(:severity, Ecto.Enum, values: [:low, :medium, :high, :critical])
    field(:source, :string)
    field(:status, Ecto.Enum, values: [:active, :acknowledged, :resolved])
    field(:acknowledged_at, :utc_datetime)
    field(:resolved_at, :utc_datetime)
    field(:escalation_level, :integer, default: 0)
    field(:next_escalation_at, :utc_datetime)

    belongs_to(:patient, Ankaa.Accounts.User)
    belongs_to(:acknowledged_by, Ankaa.Accounts.User, references: :id)
    has_many(:deliveries, Ankaa.Notifications.Delivery)

    timestamps()
  end

  # Changeset and query functions
end
