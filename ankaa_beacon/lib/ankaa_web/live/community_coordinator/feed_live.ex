defmodule AnkaaWeb.Community.Feed do
  @moduledoc """
  LiveView for the Community Coordinator Feed page.
  """
  use AnkaaWeb, :live_view

  alias Ankaa.Communities

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    if user.organization_id do
      org = Communities.get_organization!(user.organization_id)

      {:ok,
       assign(socket,
         org: org,
         # Fetch Data
         posts: Communities.list_posts(org.id),
         resources: Communities.list_resources(org.id),
         board_items: Communities.list_approved_board_items(org.id),
         # Initialize Item Form
         item_form: to_form(Communities.change_board_item(%Ankaa.Community.BoardItem{})),
         show_item_form: false
       )}
    else
      # Handle users with no community
      {:ok, assign(socket, org: nil)}
    end
  end

  @impl true
  def handle_event("save_item", %{"board_item" => params}, socket) do
    params = params
      |> Map.put("organization_id", socket.assigns.org.id)
      |> Map.put("user_id", socket.assigns.current_user.id)
      |> Map.put("status", "pending") # Always pending until Coordinator approves

    case Communities.create_board_item(params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Post submitted for approval.")
         |> assign(show_item_form: false)}

      {:error, changeset} ->
        {:noreply, assign(socket, item_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("toggle_form", _, socket) do
    {:noreply, assign(socket, show_item_form: !socket.assigns.show_item_form)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-10">
      <%= if @org do %>
        <div class="mb-8">
          <h2 class="text-2xl font-bold text-gray-900">{@org.name} Community</h2>
          <p class="text-sm text-gray-500">News, Resources, and Support</p>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">

          <div class="space-y-6">
            <h3 class="font-semibold text-gray-900 flex items-center">
              <.icon name="hero-megaphone" class="w-5 h-5 mr-2 text-purple-600"/> News & Alerts
            </h3>
            <div class="space-y-4">
              <%= for post <- @posts do %>
                <div class="bg-white shadow rounded-lg p-4 border-l-4 border-purple-500">
                   <div class="flex justify-between">
                    <h4 class="font-bold text-gray-900">{post.title}</h4>
                    <%= if post.is_pinned do %>
                      <.icon name="hero-star-solid" class="w-4 h-4 text-yellow-400"/>
                    <% end %>
                   </div>
                   <p class="text-sm text-gray-700 mt-2">{post.body}</p>
                   <p class="text-xs text-gray-400 mt-2">{Calendar.strftime(post.published_at || post.inserted_at, "%b %d")}</p>
                </div>
              <% end %>
              <%= if Enum.empty?(@posts), do: empty_state("No announcements.") %>
            </div>
          </div>

          <div class="space-y-6">
            <div class="flex justify-between items-center">
              <h3 class="font-semibold text-gray-900 flex items-center">
                <.icon name="hero-hand-raised" class="w-5 h-5 mr-2 text-amber-600"/> Supply Board
              </h3>
              <button phx-click="toggle_form" class="text-xs font-bold text-purple-600">
                {if @show_item_form, do: "Cancel", else: "+ Post Request"}
              </button>
            </div>

            <%= if @show_item_form do %>
              <div class="bg-gray-50 p-4 rounded-lg mb-4">
                <.simple_form for={@item_form} phx-submit="save_item">
                  <.input field={@item_form[:type]} type="select" options={["Requesting": "requesting", "Offering": "offering"]} label="Type" />
                  <.input field={@item_form[:item_name]} label="Item Name" placeholder="e.g. 15g Needles" />
                  <.input field={@item_form[:description]} type="textarea" label="Details" rows="2" />
                  <:actions>
                    <.button class="w-full text-xs">Submit for Approval</.button>
                  </:actions>
                </.simple_form>
              </div>
            <% end %>

            <div class="space-y-4">
              <%= for item <- @board_items do %>
                 <div class="bg-white shadow rounded-lg p-4">
                    <span class={["text-xs font-bold uppercase", if(item.type == "offering", do: "text-green-600", else: "text-blue-600")]}>
                      {item.type}
                    </span>
                    <h4 class="font-medium text-gray-900">{item.item_name}</h4>
                    <p class="text-sm text-gray-600">{item.description}</p>
                    <p class="text-xs text-gray-400 mt-2">Posted by: {item.user.email}</p>
                 </div>
              <% end %>
               <%= if Enum.empty?(@board_items), do: empty_state("Board is empty.") %>
            </div>
          </div>

          <div class="space-y-6">
            <h3 class="font-semibold text-gray-900 flex items-center">
              <.icon name="hero-book-open" class="w-5 h-5 mr-2 text-teal-600"/> Library
            </h3>
            <div class="space-y-4">
              <%= for resource <- @resources do %>
                <a href={resource.url} target="_blank" class="block bg-white shadow rounded-lg p-4 hover:ring-1 hover:ring-teal-500">
                   <h4 class="font-bold text-teal-700">{resource.title} ↗</h4>
                   <span class="inline-flex mt-1 items-center rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-600">
                      {resource.category}
                   </span>
                   <p class="text-sm text-gray-600 mt-2">{resource.description}</p>
                </a>
              <% end %>
              <%= if Enum.empty?(@resources), do: empty_state("Library is empty.") %>
            </div>
          </div>

        </div>
      <% else %>
        <div class="text-center py-20">
          <h3 class="text-lg font-medium text-gray-900">No Community Found</h3>
          <p class="text-gray-500">You aren't linked to a clinic organization yet.</p>
        </div>
      <% end %>
    </div>
    """
  end

  defp empty_state(msg) do
    assigns = %{msg: msg}
    ~H"""
    <div class="text-center py-6 border-2 border-dashed border-gray-200 rounded-lg text-sm text-gray-400">
      {@msg}
    </div>
    """
  end
end
