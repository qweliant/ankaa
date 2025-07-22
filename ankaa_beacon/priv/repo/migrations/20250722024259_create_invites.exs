defmodule Ankaa.Repo.Migrations.CreateInvites do
  use Ecto.Migration

  def change do
    create table(:invites) do
      add(:invitee_email, :string, null: false)
      add(:invitee_role, :string, null: false)
      add(:token, :string, null: false)
      add(:status, :string, null: false, default: "pending")
      add(:expires_at, :utc_datetime, null: false)

      # The user who sent the invite (required)
      add(:inviter_id, references(:users, on_delete: :nothing, type: :binary_id), null: false)

      # The patient this invite is for (optional)
      add(:patient_id, references(:patients, on_delete: :nothing, type: :binary_id))

      timestamps()
    end

    # Add indexes for faster lookups
    create(index(:invites, [:inviter_id]))
    create(index(:invites, [:patient_id]))
    create(unique_index(:invites, [:token], name: :invites_token_index))
  end
end
