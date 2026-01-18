defmodule AnkaaWeb.Community.Components.FeedComponent do
  use AnkaaWeb, :live_component

  alias Ankaa.Communities
  alias Ankaa.Community.{Post, BoardItem}
  alias Phoenix.HTML.Form

  @impl true
  def update(assigns, socket) do
    org_id = assigns.org.id
    current_user_id = assigns.current_user.id
    # "admin", "moderator", or "member"
    role = assigns.current_role
    is_mod = Communities.moderator?(role)

    posts = Communities.list_posts(org_id)

    all_items = Communities.list_all_board_items(org_id)

    board_items =
      if is_mod do
        all_items
      else
        Enum.filter(all_items, fn item ->
          item.status == "approved" or item.user_id == current_user_id
        end)
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       # Helper for the template
       is_mod: is_mod,
       posts: posts,
       board_items: board_items,
       post_form: to_form(Communities.change_post(%Post{type: "announcement"})),
       item_form: to_form(Communities.change_board_item(%BoardItem{})),
       show_post_form: false,
       show_item_form: false
     )}
  end

  @impl true
  def handle_event("toggle_post_form", _, socket),
    do: {:noreply, assign(socket, show_post_form: !socket.assigns.show_post_form)}

  @impl true
  def handle_event("toggle_item_form", _, socket),
    do: {:noreply, assign(socket, show_item_form: !socket.assigns.show_item_form)}

  @impl true
  def handle_event("save_post", %{"post" => params}, socket) do
    if !socket.assigns.is_mod, do: {:noreply, put_flash(socket, :error, "Unauthorized")}

    # Default type if missing
    params =
      params
      |> Map.put("organization_id", socket.assigns.org.id)
      |> Map.put("author_id", socket.assigns.current_user.id)
      |> Map.put_new("type", "announcement")

    case Communities.create_post(params) do
      {:ok, _} ->
        # Reset form to default announcement
        empty_changeset = Communities.change_post(%Post{type: "announcement"})

        {:noreply,
         socket
         |> assign(
           show_post_form: false,
           posts: Communities.list_posts(socket.assigns.org.id),
           post_form: to_form(empty_changeset)
         )
         |> put_flash(:info, "Published!")}

      {:error, changeset} ->
        {:noreply, assign(socket, post_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("save_item", %{"board_item" => params}, socket) do
    params =
      params
      |> Map.put("organization_id", socket.assigns.org.id)
      |> Map.put("user_id", socket.assigns.current_user.id)
      |> Map.put("status", "pending")

    case Communities.create_board_item(params) do
      {:ok, _} ->
        # Refresh via parent or simple redirect logic
        send(self(), :refresh_feed)
        {:noreply,
         socket |> assign(show_item_form: false) |> put_flash(:info, "Request submitted.")}
      {:error, changeset} ->
        {:noreply, assign(socket, item_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("moderate_item", %{"id" => id, "status" => status}, socket) do
    if socket.assigns.is_mod == false do
      {:noreply, put_flash(socket, :error, "Unauthorized.")}
    else
      item = Enum.find(socket.assigns.board_items, &(&1.id == id))
      {:ok, _} = Communities.update_board_item_status(item, status)

      updated_items =
        if socket.assigns.is_mod do
          Communities.list_all_board_items(socket.assigns.org.id)
        else
          Communities.list_approved_board_items(socket.assigns.org.id)
        end

      {:noreply,
       socket
       |> assign(board_items: updated_items)
       |> put_flash(:info, "Item marked as #{status}")}
    end
  end

  @impl true
  def handle_event("validate_post", %{"post" => params}, socket) do
    changeset =
      %Post{}
      |> Communities.change_post(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, post_form: to_form(changeset))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8 animate-fade-in-up">

      <div class="lg:col-span-2 space-y-6">
        <div class="flex items-center justify-between">
          <h2 class="text-xl font-bold text-slate-800 flex items-center gap-2">
            <.icon name="hero-megaphone" class="w-6 h-6 text-purple-600" /> Community News
          </h2>
          <%= if @is_mod do %>
            <button phx-click="toggle_post_form" phx-target={@myself} class="text-sm font-bold text-purple-600 hover:text-purple-700">
              {if @show_post_form, do: "Cancel", else: "+ New Post"}
            </button>
          <% end %>
        </div>

        <%= if @show_post_form do %>
          <div class="bg-gray-50 p-4 rounded-xl border border-gray-200">
            <.simple_form for={@post_form} phx-change="validate_post" phx-submit="save_post" phx-target={@myself}>
              <.input field={@post_form[:title]} placeholder="Headline" required />

              <.input field={@post_form[:type]} type="select" label="Post Type" options={["Announcement": "announcement", "Action Item (Advocacy)": "action_item", "Event": "event"]} />

              <%= if Form.input_value(@post_form, :type) == "action_item" do %>
                <div class="p-4 bg-amber-50 border border-amber-100 rounded-lg space-y-3 animate-in fade-in slide-in-from-top-2">
                  <h4 class="text-xs font-bold text-amber-700 uppercase tracking-wide">
                    Advocacy Settings
                  </h4>
                  <div class="grid grid-cols-2 gap-3">
                    <.input field={@post_form[:action_label]} label="Button Label" placeholder="e.g. Email Landlord" />
                    <.input field={@post_form[:action_target]} label="Target Email" placeholder="manager@apts.com" />
                  </div>
                  <.input field={@post_form[:action_subject]} label="Email Subject Line" />
                  <.input field={@post_form[:action_script]} type="textarea" label="Email Body / Script" rows="3" />
                </div>
              <% end %>

              <.input field={@post_form[:body]} type="textarea" placeholder="Message..." rows="3" required />
              <.input field={@post_form[:is_pinned]} type="checkbox" label="Pin to top" />

              <:actions><.button class="w-full">Publish</.button></:actions>
            </.simple_form>
          </div>
        <% end %>

        <div class="space-y-4">
          <%= for post <- @posts do %>
            <div class={[
                "bg-white shadow-sm rounded-xl p-5 border-l-4 transition-all hover:shadow-md",
                if(post.type == "action_item", do: "border-amber-400 bg-amber-50/10", else: "border-purple-500")
              ]}>

              <div class="flex justify-between items-start">
                <h4 class="font-bold text-gray-900 text-lg flex items-center gap-2">
                  <%= if post.type == "action_item" do %>
                    <.icon name="hero-bolt-solid" class="w-5 h-5 text-amber-500" />
                  <% end %>
                  {post.title}
                </h4>
                <%= if post.is_pinned do %>
                  <.icon name="hero-star-solid" class="w-5 h-5 text-yellow-400" />
                <% end %>
              </div>

              <p class="text-xs text-gray-500 mt-1 mb-3">
                {Calendar.strftime(post.inserted_at, "%b %d")} • {String.capitalize(post.type)}
              </p>

              <p class="text-gray-700 whitespace-pre-wrap">{post.body}</p>

              <%= if post.type == "action_item" do %>
                  <div class="mt-4 pt-3 border-t border-amber-100/50">
                    <a href={"mailto:#{post.action_target}?subject=#{URI.encode(post.action_subject || "")}&body=#{URI.encode(post.action_script || "")}"}
                       class="inline-flex items-center justify-center w-full bg-amber-100 text-amber-800 px-4 py-2.5 rounded-lg text-sm font-bold hover:bg-amber-200 transition-colors shadow-sm">
                      <.icon name="hero-envelope" class="w-4 h-4 mr-2" />
                      {post.action_label || "Take Action"}
                    </a>
                  </div>
              <% end %>
            </div>
          <% end %>
          {if Enum.empty?(@posts), do: render_empty("No news yet.")}
        </div>
      </div>

      <div class="space-y-6">
        <div class="flex items-center justify-between">
          <h3 class="text-lg font-semibold text-gray-900 flex items-center">
            <.icon name="hero-clipboard-document-check" class="w-5 h-5 mr-2 text-amber-600" />
            Supply Moderation
          </h3>
          <%= if @is_mod do %>
            <span class="inline-flex items-center rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-medium text-amber-800">
              {Enum.count(@board_items, &(&1.status == "pending"))} Pending
            </span>
          <% end %>
        </div>

        <button phx-click="toggle_item_form" phx-target={@myself} class="w-full text-center text-sm font-bold text-purple-600 border border-purple-200 rounded-lg py-2 hover:bg-purple-50 mb-2">
           {if @show_item_form, do: "Cancel Request", else: "+ Post Request / Offer"}
        </button>

        <%= if @show_item_form do %>
          <div class="bg-gray-50 p-4 rounded-xl border border-gray-200 mb-4">
            <.simple_form for={@item_form} phx-submit="save_item" phx-target={@myself}>
              <.input field={@item_form[:type]} type="select" options={["Request": "requesting", "Offer": "offering"]} />
              <.input field={@item_form[:item_name]} placeholder="Item name" required />
              <.input field={@item_form[:description]} type="textarea" rows="2" placeholder="Details..." />
              <:actions><.button class="w-full">Submit</.button></:actions>
            </.simple_form>
          </div>
        <% end %>

        <div class="space-y-4">
          <%= for item <- @board_items do %>
            <%= if item.status == "approved" or @is_mod or item.user_id == @current_user.id do %>
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
                <p class="text-xs text-gray-500">by {if item.user_id == @current_user.id, do: "You", else: item.user.email}</p>
                <p class="text-sm text-gray-700 mt-2">{item.description}</p>

                <%= if @is_mod and item.status == "pending" do %>
                  <div class="mt-4 flex gap-2 border-t pt-3">
                    <button phx-click="moderate_item" phx-value-id={item.id} phx-value-status="approved" phx-target={@myself} class="flex-1 rounded bg-green-50 px-2 py-1 text-xs font-semibold text-green-600 hover:bg-green-100">Approve</button>
                    <button phx-click="moderate_item" phx-value-id={item.id} phx-value-status="rejected" phx-target={@myself} class="flex-1 rounded bg-red-50 px-2 py-1 text-xs font-semibold text-red-600 hover:bg-red-100">Reject</button>
                  </div>
                <% end %>
              </div>
            <% end %>
          <% end %>
          {if Enum.empty?(@board_items), do: render_empty("No active requests.")}
        </div>
      </div>
    </div>
    """
  end

  defp render_empty(msg) do
    assigns = %{msg: msg}

    ~H"""
    <div class="text-center py-6 text-gray-400 text-sm border-2 border-dashed border-gray-200 rounded-lg">
      {@msg}
    </div>
    """
  end
end
