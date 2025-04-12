defmodule Ankaa.Notifications.Alert do
  @moduledoc """
  Schema and functions for alerts.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ankaa.Repo

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

  @doc """
  Creates a changeset for an alert.
  """
  def changeset(alert, attrs) do
    alert
    |> cast(attrs, [
      :title,
      :message,
      :severity,
      :source,
      :status,
      :acknowledged_at,
      :resolved_at,
      :escalation_level,
      :next_escalation_at,
      :patient_id
    ])
    |> validate_required([:title, :message, :severity, :source])
    |> foreign_key_constraint(:patient_id)
  end

  @doc """
  Creates a new alert.
  """
  @spec create(map()) :: {:ok, Alert.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  # Changeset and query functions
end
