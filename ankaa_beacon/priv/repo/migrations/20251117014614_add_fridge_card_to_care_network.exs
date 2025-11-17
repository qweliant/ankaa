defmodule Ankaa.Repo.Migrations.AddFridgeCardToCareNetwork do
  use Ecto.Migration

  def change do
    alter table(:care_network) do
      add(:fridge_card_notes, :text, default: nil)
    end
  end
end
