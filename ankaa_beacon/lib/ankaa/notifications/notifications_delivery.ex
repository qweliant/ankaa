defmodule Ankaa.Notifications.Delivery do
  @moduledoc """
  Schema and functions for tracking notification deliveries.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "alert_deliveries" do
    field :channel, Ecto.Enum, values: [:sms, :email, :app, :voice]
    field :recipient, :string
    field :status, Ecto.Enum, values: [:pending, :delivered, :failed]
    field :error_message, :string

    belongs_to :alert, Ankaa.Notifications.Alert

    timestamps()
  end

  # Changeset and query functions
end
