defmodule Ankaa.Communities do
  @moduledoc """
  The Community context.
  """
  import Ecto.Query, warn: false
  alias Ankaa.Repo
  alias Ankaa.Community.{Post, Resource, BoardItem, Organization, OrganizationMembership}
  alias Ankaa.Accounts.{User}

  @doc """
  Adds a user to an organization with a specific contextual role.
  Replaces the old 'assign_organization'.

  - Parameters:
    - user: %User{} struct of the user to add
    - organization_id: ID of the organization to join
    - role: String representing the user's role in this org (e.g. "admin", "coordinator", "patient", "family", "social_worker")

  Returns {:ok, %OrganizationMembership{}} or {:error, %Ecto.Changeset{}}

  Note: This does NOT check if the user is already a member. The calling code should handle that if needed.
  """
  def add_member(%User{} = user, organization_id, role \\ "member") do
    %OrganizationMembership{}
    |> OrganizationMembership.changeset(%{
      user_id: user.id,
      organization_id: organization_id,
      role: role,
      # Auto-activate if added by system/admin
      status: "active"
    })
    |> Repo.insert()
  end

  @doc """
  Lists all users in an organization.
  Updated to join the new membership table.
  Returns a list of Maps: [%{user: User, role: "admin"}, ...]
  """
  def list_members(organization_id) do
    from(u in User,
      join: m in OrganizationMembership,
      on: m.user_id == u.id,
      where: m.organization_id == ^organization_id,
      order_by: [asc: m.role, asc: u.last_name],
      select: %{user: u, role: m.role, status: m.status, joined_at: m.inserted_at}
    )
    |> Repo.all()
  end

  @doc """
  Removes a user from a specific organization.
  Now requires organization_id because a user can belong to many.
  """
  def remove_member(%User{} = user, organization_id) do
    from(m in OrganizationMembership,
      where: m.user_id == ^user.id and m.organization_id == ^organization_id
    )
    |> Repo.delete_all()
  end

  @doc """
  Checks if a user is a member of an org.
  Useful for Authorization plugs.
  """
  def get_membership(user_id, organization_id) do
    Repo.get_by(OrganizationMembership, user_id: user_id, organization_id: organization_id)
  end

  @doc """
  Creates a new organization.
  (Useful for the first Doctor registering a clinic)
  """
  def create_organization(attrs \\ %{}) do
    %Organization{}
    |> Organization.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates an organization, adds the creator as admin, and seeds default content.
  """
  def create_organization_with_defaults(%User{} = creator, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:org, Organization.changeset(%Organization{}, attrs))
    |> Ecto.Multi.run(:membership, fn repo, %{org: org} ->
      %OrganizationMembership{}
      |> OrganizationMembership.changeset(%{
        user_id: creator.id,
        organization_id: org.id,
        role: "admin",
        status: "active"
      })
      |> repo.insert()
    end)
    |> Ecto.Multi.run(:welcome_post, fn repo, %{org: org} ->
      %Post{}
      |> Post.changeset(%{
        organization_id: org.id,
        author_id: creator.id,
        title: "Welcome to #{org.name}",
        body: "This is your Community News feed. As a coordinator, you can pin important announcements here.",
        is_pinned: true,
        published_at: DateTime.utc_now(),
        type: "announcement"
      })
      |> repo.insert()
    end)
    |> Ecto.Multi.run(:resource, fn repo, %{org: org} ->
      %Resource{}
      |> Resource.changeset(%{
        organization_id: org.id,
        user_id: creator.id,
        title: "Getting Started with SafeHemo",
        description: "A guide on how to use the Resource Library.",
        url: "https://safehemo.com",
        category: "guide"
      })
      |> repo.insert()
    end)
    |> Repo.transaction()
  end

  def get_organization!(id), do: Repo.get!(Organization, id)

  @doc """
  Returns the role string ("coordinator", "patient", etc) for a user in a specific org.
  Returns nil if not a member.
  """
  def get_user_role_in_org(%User{} = user, %Organization{} = org) do
    case Repo.get_by(OrganizationMembership, user_id: user.id, organization_id: org.id) do
      %OrganizationMembership{role: role, status: "active"} -> role
      _ -> nil
    end
  end

  def moderator?(role) do
    role in ["admin", "moderator"]
  end

  @doc """
  Returns a list of organizations the user belongs to.
  Queries the OrganizationMembership join table.
  """
  def list_communities_for_user(%User{} = user) do
    from(o in Organization,
      join: m in assoc(o, :memberships),
      where: m.user_id == ^user.id,
      where: m.status == "active",
      order_by: [asc: o.name],
      select: o
    )
    |> Repo.all()
  end

  @doc """
  Returns a list of organizations the user belongs to.
  """
  def list_organizations_for_user(%User{} = user) do
    from(o in Organization,
      join: m in assoc(o, :memberships),
      where: m.user_id == ^user.id,
      order_by: [asc: o.name],
      select: o
    )
    |> Repo.all()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking organization changes.
  """
  def change_organization(%Organization{} = organization, attrs \\ %{}) do
    Organization.changeset(organization, attrs)
  end

  @doc """
  Removes a user from the community (sets organization_id to nil).
  Does NOT delete the user account.
  """
  def remove_member(%User{} = user) do
    user
    |> User.organization_changeset(%{organization_id: nil})
    |> Repo.update()
  end

  def get_member!(id), do: Repo.get!(User, id)

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

  def delete_board_item(%BoardItem{} = item) do
    Repo.delete(item)
  end

  def get_board_item!(id), do: Repo.get!(BoardItem, id)
end
