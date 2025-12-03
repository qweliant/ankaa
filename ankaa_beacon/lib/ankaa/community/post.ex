defmodule Ankaa.Community.Post do
  @moduledoc """
  Ecto schema for community posts such as announcements, events, and action items.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "community_posts" do
    field(:title, :string)
    field(:body, :string)
    field(:type, :string)
    field(:is_pinned, :boolean, default: false)
    field(:published_at, :utc_datetime)
    field(:action_target, :string)
    field(:action_subject, :string)
    field(:action_script, :string)
    field(:action_label, :string)
    field(:action_link, :string)
    field(:action_count, :integer, default: 0)

    belongs_to :organization, Ankaa.Accounts.Organization
    belongs_to :author, Ankaa.Accounts.User

    timestamps()
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [
      :title, :body, :type, :is_pinned, :published_at, :organization_id, :author_id,
      :action_target, :action_subject, :action_script, :action_count,
      :action_label, :action_link
    ])
    |> validate_required([:title, :type, :organization_id, :author_id])
    |> validate_inclusion(:type, ["announcement", "event", "action_item"])
  end
end
