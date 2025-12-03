defmodule Ankaa.Repo.Migrations.CreateCommunityTables do
  use Ecto.Migration

  def change do
    create table(:community_posts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all), null: false
      add :author_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      add :title, :string, null: false
      add :body, :text
      add :type, :string, default: "announcement"

      add :action_target, :string
      add :action_subject, :string
      add :action_script, :text
      add :supporter_count, :integer, default: 0
      add :action_label, :string
      add :action_link, :string
      add :action_count, :integer

      add :is_pinned, :boolean, default: false
      add :published_at, :utc_datetime

      timestamps()
    end

    create index(:community_posts, [:organization_id])
    create index(:community_posts, [:published_at])

    create table(:community_resources, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all),
        null: false

      add :title, :string, null: false
      add :description, :text
      add :url, :string
      add :category, :string

      timestamps()
    end

    create index(:community_resources, [:organization_id, :category])

    create table(:community_board_items, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all),
        null: false

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      add :type, :string, null: false
      add :item_name, :string, null: false
      add :description, :text
      add :status, :string, default: "pending"

      timestamps()
    end

    create index(:community_board_items, [:organization_id, :status])
  end
end
