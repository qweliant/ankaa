defmodule Ankaa.Notifications.Delivery do
  @moduledoc """
  Schema and functions for tracking notification deliveries.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "alert_deliveries" do
    field(:status, Ecto.Enum, values: [:pending, :in_progress, :delivered, :failed])
    field(:attempt_count, :integer, default: 0)
    field(:last_attempt_at, :utc_datetime)
    field(:error_code, :string)
    field(:error_message, :string)
    field(:metadata, :map, default: %{})

    belongs_to(:alert, Ankaa.Notifications.Alert)
    belongs_to(:channel, Ankaa.Notifications.Channel)

    timestamps()
  end

  @doc """
  Creates a changeset for a delivery.
  """
  def changeset(delivery, attrs) do
    delivery
    |> cast(attrs, [
      :status,
      :attempt_count,
      :last_attempt_at,
      :error_code,
      :error_message,
      :metadata
    ])
    |> validate_required([:status])
    |> foreign_key_constraint(:alert_id)
    |> foreign_key_constraint(:channel_id)
  end

  @doc """
  Records a delivery attempt.
  """
  @spec record_attempt(Delivery.t(), :ok | {:error, term()}) ::
          {:ok, Delivery.t()} | {:error, term()}
  def record_attempt(delivery, result) do
    attrs = %{
      attempt_count: delivery.attempt_count + 1,
      last_attempt_at: DateTime.utc_now()
    }

    case result do
      :ok ->
        delivery
        |> changeset(Map.merge(attrs, %{status: :delivered}))
        |> Repo.update()

      {:error, reason} ->
        delivery
        |> changeset(
          Map.merge(attrs, %{
            status: :failed,
            error_code: error_code(reason),
            error_message: error_message(reason)
          })
        )
        |> Repo.update()
    end
  end

  defp error_code(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp error_code(_), do: "unknown"

  defp error_message(reason) when is_binary(reason), do: reason
  defp error_message(reason) when is_atom(reason), do: "Delivery failed: #{reason}"
  defp error_message(_), do: "Unknown delivery error"
end
