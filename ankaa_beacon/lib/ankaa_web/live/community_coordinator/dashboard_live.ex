defmodule AnkaaWeb.Community.DashboardLive do
  use AnkaaWeb, :live_view

  alias Ankaa.Community
  alias Ankaa.Community.{Post, Resource}
  alias Ankaa.Accounts
    alias Phoenix.HTML.Form


  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    if user.organization_id do
      org = Accounts.get_organization!(user.organization_id)

      # Load Dashboard Data
      posts = Community.list_posts(org.id)
      resources = Community.list_resources(org.id)
      board_items = Community.list_all_board_items(org.id)

      # Initialize Forms
      # Note: We default the post type to "announcement" to avoid nil errors in the form
      post_changeset = Community.change_post(%Post{type: "announcement"})
      resource_changeset = Community.change_resource(%Resource{})

      {:ok,
       assign(socket,
         org: org,
         posts: posts,
         resources: resources,
         board_items: board_items,
         # Forms
         post_form: to_form(post_changeset),
         resource_form: to_form(resource_changeset),
         # Toggles
         show_post_form: false,
         show_resource_form: false
       )}
    else
      {:ok, redirect(socket, to: ~p"/")}
    end
  end

  @impl true
  def handle_event("toggle_post_form", _, socket) do
    {:noreply, assign(socket, show_post_form: !socket.assigns.show_post_form)}
  end

  @impl true
  def handle_event("toggle_resource_form", _, socket) do
    {:noreply, assign(socket, show_resource_form: !socket.assigns.show_resource_form)}
  end

  # Validates form to enable dynamic fields (Action Item inputs)
  @impl true
  def handle_event("validate_post", %{"post" => params}, socket) do
    changeset =
      %Post{}
      |> Community.change_post(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, post_form: to_form(changeset))}
  end

  @impl true
  def handle_event("save_post", %{"post" => params}, socket) do
    params = params
      |> Map.put("organization_id", socket.assigns.org.id)
      |> Map.put("author_id", socket.assigns.current_user.id)
      |> Map.put_new("type", "announcement")

    case Community.create_post(params) do
      {:ok, _post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Post published successfully.")
         |> assign(show_post_form: false)
         |> assign(posts: Community.list_posts(socket.assigns.org.id))
         |> assign(post_form: to_form(Community.change_post(%Post{type: "announcement"})))}

      {:error, changeset} ->
        {:noreply, assign(socket, post_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("save_resource", %{"resource" => params}, socket) do
    params = Map.put(params, "organization_id", socket.assigns.org.id)

    case Community.create_resource(params) do
      {:ok, _resource} ->
        {:noreply,
         socket
         |> put_flash(:info, "Resource added to library.")
         |> assign(show_resource_form: false)
         |> assign(resources: Community.list_resources(socket.assigns.org.id))
         |> assign(resource_form: to_form(Community.change_resource(%Resource{})))}

      {:error, changeset} ->
        {:noreply, assign(socket, resource_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("moderate_item", %{"id" => id, "status" => status}, socket) do
    item = Enum.find(socket.assigns.board_items, &(&1.id == id))

    if item do
      {:ok, _updated} = Community.update_board_item_status(item, status)

      {:noreply,
       socket
       |> put_flash(:info, "Item marked as #{status}.")
       |> assign(board_items: Community.list_all_board_items(socket.assigns.org.id))}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("invite_member", %{"email" => email}, socket) do
    attrs = %{
      "invitee_email" => email,
      "invitee_role" => "patient", # Default role for community invites
      "organization_id" => socket.assigns.org.id, # Forces them into THIS community
      "inviter_id" => socket.assigns.current_user.id
    }

    case Ankaa.Invites.create_invite(socket.assigns.current_user, attrs) do
      {:ok, _invite} ->
        {:noreply, put_flash(socket, :info, "Community invite sent to #{email}.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to send invite.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-10">

      <div class="bg-white shadow rounded-lg p-6 mb-8">
        <h3 class="text-lg font-medium text-gray-900 mb-4">Grow the Community</h3>
        <form phx-submit="invite_member" class="flex gap-2">
          <input
            type="email"
            name="email"
            placeholder="Email address..."
            required
            class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-inset focus:ring-purple-600 sm:text-sm sm:leading-6"
          />
          <button class="rounded-md bg-purple-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-purple-500">
            Invite
          </button>
        </form>
      </div>

      <div class="md:flex md:items-center md:justify-between mb-8 border-b border-gray-200 pb-5">
        <div class="min-w-0 flex-1">
          <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:truncate sm:text-3xl sm:tracking-tight">
            Community Hub
          </h2>
          <p class="mt-1 text-sm text-gray-500">
            Managing: <span class="font-semibold text-purple-600">{@org.name}</span>
          </p>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">

        <div class="space-y-6">
          <div class="flex items-center justify-between">
            <h3 class="text-lg font-semibold text-gray-900 flex items-center">
              <.icon name="hero-megaphone" class="w-5 h-5 mr-2 text-purple-600" /> Community Feed
            </h3>
            <button
              phx-click="toggle_post_form"
              class="text-sm text-purple-600 hover:text-purple-900 font-medium"
            >
              {if @show_post_form, do: "Cancel", else: "+ New Post"}
            </button>
          </div>

          <%= if @show_post_form do %>
            <div class="bg-gray-50 p-4 rounded-lg border border-gray-200">
              <.simple_form for={@post_form} phx-change="validate_post" phx-submit="save_post">

                <.input field={@post_form[:type]} type="select" label="Post Type" options={[
                  "General Announcement": "announcement",
                  "Action Item (Advocacy)": "action_item",
                  "Event": "event"
                ]} />

                <.input field={@post_form[:title]} label="Headline" placeholder="Title..." required />

                <%= if Form.input_value(@post_form, :type) == "action_item" do %>
                  <div class="p-3 bg-amber-50 border border-amber-100 rounded-md space-y-3 animate-in fade-in slide-in-from-top-2">
                    <h4 class="text-xs font-bold text-amber-700 uppercase tracking-wide">Advocacy Settings</h4>
                    <div class="grid grid-cols-2 gap-3">
                       <.input field={@post_form[:action_label]} label="Button Label" placeholder="e.g. Email Landlord" />
                       <.input field={@post_form[:action_target]} label="Target Email" placeholder="manager@apts.com" />
                    </div>
                    <.input field={@post_form[:action_subject]} label="Subject Line" />
                    <.input field={@post_form[:action_script]} type="textarea" label="Email Body" rows="3" />
                  </div>
                <% end %>

                <.input field={@post_form[:body]} type="textarea" label="Message" rows="3" required />
                <.input field={@post_form[:is_pinned]} type="checkbox" label="Pin to top" />

                <:actions>
                  <.button class="w-full">Publish</.button>
                </:actions>
              </.simple_form>
            </div>
          <% end %>

          <div class="space-y-4">
            <%= for post <- @posts do %>
              <div class={[
                "bg-white shadow rounded-lg p-4 border-l-4",
                if(post.type == "action_item", do: "border-amber-500", else: "border-purple-500")
              ]}>
                <div class="flex justify-between items-start">
                  <h4 class="font-bold text-gray-900 flex items-center gap-2">
                    <%= if post.type == "action_item" do %>
                      <.icon name="hero-bolt-solid" class="w-4 h-4 text-amber-500" />
                    <% end %>
                    {post.title}
                  </h4>
                  <%= if post.is_pinned do %>
                    <.icon name="hero-star-solid" class="w-4 h-4 text-yellow-400" />
                  <% end %>
                </div>
                <p class="text-xs text-gray-500 mt-1">
                  {Calendar.strftime(post.published_at || post.inserted_at, "%b %d")} • {String.capitalize(post.type)}
                </p>
                <p class="text-sm text-gray-700 mt-2 whitespace-pre-wrap">{post.body}</p>

                <%= if post.type == "action_item" do %>
                  <div class="mt-4 pt-3 border-t border-gray-100">
                    <a href={"mailto:#{post.action_target}?subject=#{URI.encode(post.action_subject || "")}&body=#{URI.encode(post.action_script || "")}"}
                       class="flex items-center justify-center w-full rounded-md bg-amber-100 px-3 py-2 text-sm font-semibold text-amber-800 shadow-sm hover:bg-amber-200">
                      <.icon name="hero-envelope" class="w-4 h-4 mr-2" />
                      {post.action_label || "Take Action"}
                    </a>
                  </div>
                <% end %>
              </div>
            <% end %>
            {if Enum.empty?(@posts), do: render_empty_state("No announcements yet.")}
          </div>
        </div>

        <div class="space-y-6">
          <div class="flex items-center justify-between">
            <h3 class="text-lg font-semibold text-gray-900 flex items-center">
              <.icon name="hero-clipboard-document-check" class="w-5 h-5 mr-2 text-amber-600" />
              Supply Moderation
            </h3>
            <span class="inline-flex items-center rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-medium text-amber-800">
              {Enum.count(@board_items, &(&1.status == "pending"))} Pending
            </span>
          </div>

          <div class="space-y-4">
            <%= for item <- @board_items do %>
              <%= if item.status in ["pending", "approved"] do %>
                <div class={[
                  "bg-white shadow rounded-lg p-4 border-l-4",
                  if(item.status == "pending", do: "border-amber-400", else: "border-green-400")
                ]}>
                  <div class="flex justify-between">
                    <span class={[
                      "text-xs font-bold uppercase tracking-wide",
                      if(item.type == "offering", do: "text-green-600", else: "text-blue-600")
                    ]}>
                      {item.type}
                    </span>
                    <span class="text-xs text-gray-400">{item.status}</span>
                  </div>

                  <h4 class="font-bold text-gray-900 mt-1">{item.item_name}</h4>
                  <p class="text-xs text-gray-500">by {item.user.email}</p>
                  <p class="text-sm text-gray-700 mt-2">{item.description}</p>

                  <%= if item.status == "pending" do %>
                    <div class="mt-4 flex gap-2 border-t pt-3">
                      <button
                        phx-click="moderate_item"
                        phx-value-id={item.id}
                        phx-value-status="approved"
                        class="flex-1 rounded bg-green-50 px-2 py-1 text-xs font-semibold text-green-600 hover:bg-green-100"
                      >
                        Approve
                      </button>
                      <button
                        phx-click="moderate_item"
                        phx-value-id={item.id}
                        phx-value-status="rejected"
                        class="flex-1 rounded bg-red-50 px-2 py-1 text-xs font-semibold text-red-600 hover:bg-red-100"
                      >
                        Reject
                      </button>
                    </div>
                  <% end %>
                </div>
              <% end %>
            <% end %>
            {if Enum.empty?(@board_items), do: render_empty_state("No active requests.")}
          </div>
        </div>

        <div class="space-y-6">
          <div class="flex items-center justify-between">
            <h3 class="text-lg font-semibold text-gray-900 flex items-center">
              <.icon name="hero-book-open" class="w-5 h-5 mr-2 text-teal-600" /> Resource Library
            </h3>
            <button
              phx-click="toggle_resource_form"
              class="text-sm text-teal-600 hover:text-teal-900 font-medium"
            >
              {if @show_resource_form, do: "Cancel", else: "+ Add Link"}
            </button>
          </div>

          <%= if @show_resource_form do %>
            <div class="bg-gray-50 p-4 rounded-lg border border-gray-200">
              <.simple_form for={@resource_form} phx-submit="save_resource">
                <.input
                  field={@resource_form[:title]}
                  label="Title"
                  placeholder="e.g. Traveling with Equipment"
                  required
                />
                <.input field={@resource_form[:url]} label="URL" placeholder="https://..." required />
                <.input
                  field={@resource_form[:category]}
                  type="select"
                  label="Category"
                  options={["Diet", "Lifestyle", "Technical", "Financial"]}
                  required
                />
                <.input
                  field={@resource_form[:description]}
                  type="textarea"
                  label="Description"
                  rows="2"
                />
                <:actions>
                  <.button class="w-full">Save Resource</.button>
                </:actions>
              </.simple_form>
            </div>
          <% end %>

          <div class="space-y-4">
            <%= for resource <- @resources do %>
              <div class="bg-white shadow rounded-lg p-4 group hover:ring-1 hover:ring-teal-500 transition-all">
                <a href={resource.url} target="_blank" class="block">
                  <div class="flex justify-between items-start">
                    <h4 class="font-bold text-teal-700 group-hover:underline">
                      {resource.title} <span class="text-gray-400 text-xs">↗</span>
                    </h4>
                    <span class="inline-flex items-center rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-600">
                      {resource.category}
                    </span>
                  </div>
                  <p class="text-sm text-gray-600 mt-1">{resource.description}</p>
                </a>
              </div>
            <% end %>
            {if Enum.empty?(@resources), do: render_empty_state("Library is empty.")}
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp render_empty_state(msg) do
    assigns = %{msg: msg}

    ~H"""
    <div class="text-center py-8 bg-gray-50 rounded-lg border-2 border-dashed border-gray-200">
      <p class="text-sm text-gray-400">{@msg}</p>
    </div>
    """
  end
end
