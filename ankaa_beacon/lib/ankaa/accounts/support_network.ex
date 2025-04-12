defmodule Ankaa.Accounts.SupportNetwork do
  use Ecto.Schema
  import Ecto.Changeset

  schema "support_network" do
    field(:relationship_type, :string)
    field(:is_primary, :boolean, default: false)
    field(:can_receive_alerts, :boolean, default: true)
    field(:can_view_history, :boolean, default: true)

    belongs_to(:patient, Ankaa.Accounts.User)
    belongs_to(:caregiver, Ankaa.Accounts.User)

    timestamps()
  end

  def changeset(support_network, attrs) do
    support_network
    |> cast(attrs, [
      :patient_id,
      :caregiver_id,
      :relationship_type,
      :is_primary,
      :can_receive_alerts,
      :can_view_history
    ])
    |> validate_required([:patient_id, :caregiver_id, :relationship_type])
    |> validate_inclusion(:relationship_type, ["family", "friend", "professional"])
    |> unique_constraint([:patient_id, :caregiver_id], name: :unique_relationship)
  end
end
