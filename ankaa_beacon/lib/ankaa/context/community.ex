defmodule Ankaa.Community do
  @moduledoc """
  The Community context.
  """
  import Ecto.Query, warn: false
  alias Ankaa.Repo
  alias Ankaa.Community.{Post, Resource, BoardItem}


  def list_posts(org_id) do
    from(p in Post,
      where: p.organization_id == ^org_id,
      order_by: [desc: p.is_pinned, desc: p.published_at]
    )
    |> Repo.all()
  end

  def create_post(attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.
  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  def create_resource(attrs \\ %{}) do
    %Resource{}
    |> Resource.changeset(attrs)
    |> Repo.insert()
  end

  def get_resource!(id), do: Repo.get!(Resource, id)

  def update_resource(%Resource{} = resource, attrs) do
    resource
    |> Resource.changeset(attrs)
    |> Repo.update()
  end

  def delete_resource(%Resource{} = resource) do
    Repo.delete(resource)
  end

  def list_resources(org_id) do
    from(r in Resource,
      where: r.organization_id == ^org_id,
      order_by: [asc: r.category, asc: r.title]
    )
    |> Repo.all()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking resource changes.
  """
  def change_resource(%Resource{} = resource, attrs \\ %{}) do
    Resource.changeset(resource, attrs)
  end

  def list_approved_board_items(org_id) do
    from(i in BoardItem,
      where: i.organization_id == ^org_id,
      where: i.status == "approved",
      preload: [:user],
      order_by: [desc: i.inserted_at]
    )
    |> Repo.all()
  end

  def create_board_item(attrs \\ %{}) do
    %BoardItem{}
    |> BoardItem.changeset(attrs)
    |> Repo.insert()
  end

  def update_board_item_status(%BoardItem{} = item, new_status) do
    item
    |> BoardItem.moderation_changeset(%{status: new_status})
    |> Repo.update()
  end

  def list_all_board_items(org_id) do
    from(i in BoardItem,
      where: i.organization_id == ^org_id,
      preload: [:user],
      order_by: [
        fragment("CASE WHEN status = 'pending' THEN 0 ELSE 1 END"),
        desc: i.inserted_at
      ]
    )
    |> Repo.all()
  end

  def change_board_item(%BoardItem{} = item, attrs \\ %{}) do
    BoardItem.changeset(item, attrs)
  end

  def moderate_item(item, status) do
    item
    |> BoardItem.moderation_changeset(%{status: status})
    |> Repo.update()
  end
end
