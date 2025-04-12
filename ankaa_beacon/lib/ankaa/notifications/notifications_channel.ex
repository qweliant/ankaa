defmodule Ankaa.Notifications.Channel do
  @moduledoc """
  Schema and functions for notification channels.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ankaa.Repo
  alias Ankaa.Notifications.Delivery

  schema "notification_channels" do
    field(:type, Ecto.Enum, values: [:sms, :email, :app, :voice])
    # phone number, email, user_id, etc.
    field(:identifier, :string)
    field(:is_active, :boolean, default: true)
    field(:last_delivery_attempt, :utc_datetime)
    field(:delivery_count, :integer, default: 0)
    field(:failure_count, :integer, default: 0)

    belongs_to(:recipient, Ankaa.Notifications.Recipient)
    has_many(:deliveries, Delivery)

    timestamps()
  end

  @doc """
  Creates a changeset for a channel.
  """
  def changeset(channel, attrs) do
    channel
    |> cast(attrs, [:type, :identifier, :is_active])
    |> validate_required([:type, :identifier])
    |> validate_format(:identifier, ~r/^[^@]+@[^@]+$/,
      message: "must be a valid email",
      if: &(&1.type == :email)
    )
    |> validate_format(:identifier, ~r/^\+?[1-9]\d{1,14}$/,
      message: "must be a valid phone number",
      if: &(&1.type == :sms)
    )
    |> validate_inclusion(:type, [:sms, :email, :app, :voice])
    |> foreign_key_constraint(:recipient_id)
  end

  @doc """
  Delivers an alert through this channel.
  """
  @spec deliver(Channel.t()) :: {:ok, Delivery.t()} | {:error, term()}
  def deliver(channel) do
    case channel.type do
      :sms -> deliver_sms(channel)
      :email -> deliver_email(channel)
      :app -> deliver_app(channel)
      :voice -> deliver_voice(channel)
    end
  end

  defp deliver_sms(channel) do
    # SMS delivery implementation
    {:ok, %Delivery{}}
  end

  defp deliver_email(channel) do
    # Email delivery implementation
    {:ok, %Delivery{}}
  end

  defp deliver_app(channel) do
    # Push notification implementation
    {:ok, %Delivery{}}
  end

  defp deliver_voice(channel) do
    # Voice call implementation
    {:ok, %Delivery{}}
  end
end
