defmodule AnkaaWeb.CommunityDashboardLive do
  use AnkaaWeb, :live_view

  alias Ankaa.Communities

  alias AnkaaWeb.Community.Components.FeedComponent
  alias AnkaaWeb.Community.Components.MembersComponent
  alias AnkaaWeb.Community.Components.ResourcesComponent


  @impl true
  def mount(params, _session, socket) do
    user = socket.assigns.current_user
    my_communities = Communities.list_organizations_for_user(user)
    target_id = params["org_id"]

    active_org =
      if target_id do
        Enum.find(my_communities, &(&1.id == target_id))
      else
        List.first(my_communities)
      end

    if active_org do
      current_role = Communities.get_user_role_in_org(user, active_org)

      {:ok,
       assign(socket,
         my_communities: my_communities,
         active_org: active_org,
         current_role: current_role,
         active_tab: :feed,
         page_title: active_org.name
       )}
    else
      {:ok, redirect(socket, to: ~p"/portal")}
    end
  end

  @impl true
  def handle_event("nav", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: String.to_existing_atom(tab))}
  end

  @impl true
  def handle_event("switch_community", %{"org_id" => id}, socket) do
    # Reload logic for the new ID
    new_org = Enum.find(socket.assigns.my_communities, &(&1.id == id))
    new_role = Communities.get_user_role_in_org(socket.assigns.current_user, new_org)

    {:noreply,
     assign(socket,
       active_org: new_org,
       current_role: new_role,
       active_tab: :feed
     )}
  end

  @impl true
  def handle_info(:refresh_feed, socket) do
    # We could force a re-render here if needed, but since we are using
    # live_component with id, sending an update to the component ID is better
    # OR simpler: just let the component handle it (which I did in FeedComponent).
    # This handler prevents the "handle_info/2 not implemented" crash.
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 flex flex-col md:flex-row">
      <aside class="w-full md:w-64 bg-white border-r border-gray-200 flex flex-col z-30">
        <div class="p-4 border-b border-gray-200">
          <label class="text-xs font-bold text-gray-400 uppercase tracking-wider block mb-1">
            Current Community
          </label>
          <form phx-change="switch_community">
            <select
              name="org_id"
              class="w-full text-sm font-bold text-slate-700 border-gray-300 rounded-lg focus:ring-purple-500 focus:border-purple-500"
            >
              <%= for org <- @my_communities do %>
                <option value={org.id} selected={org.id == @active_org.id}>{org.name}</option>
              <% end %>
            </select>
          </form>
        </div>

        <nav class="flex-1 py-6 space-y-1 px-2">
          <.nav_link active={@active_tab == :feed} tab="feed" icon="hero-home" label="Community Feed" />
          <.nav_link
            active={@active_tab == :resources}
            tab="resources"
            icon="hero-book-open"
            label="Resource Library"
          />
          <.nav_link active={@active_tab == :members} tab="members" icon="hero-users" label="Members" />

          <%= if @current_role == "coordinator" do %>
            <div class="pt-4 mt-4 border-t border-gray-100">
              <span class="px-4 text-xs font-bold text-gray-400 uppercase">Admin</span>
              <.nav_link
                active={@active_tab == :settings}
                tab="settings"
                icon="hero-cog-6-tooth"
                label="Settings"
              />
            </div>
          <% end %>
        </nav>
      </aside>

      <main class="flex-1 p-4 sm:p-8 overflow-y-auto h-screen">
        <div class="max-w-5xl mx-auto">
          <%= case @active_tab do %>
            <% :feed -> %>
              <.live_component
                module={FeedComponent}
                id={"feed-#{@active_org.id}"}
                org={@active_org}
                current_user={@current_user}
                current_role={@current_role}
              />
            <% :resources -> %>
              <.live_component
                module={ResourcesComponent}
                id={"res-#{@active_org.id}"}
                org={@active_org}
                current_user={@current_user}
                current_role={@current_role}
              />
            <% :members -> %>
              <.live_component
                module={MembersComponent}
                id={"members-#{@active_org.id}"}
                org={@active_org}
                current_user={@current_user}
                current_role={@current_role}
              />
            <% _ -> %>
              <div class="text-center py-12 text-gray-400">Under Construction</div>
          <% end %>
        </div>
      </main>
    </div>
    """
  end

  def nav_link(assigns) do
    ~H"""
    <button
      phx-click="nav"
      phx-value-tab={@tab}
      class={"w-full flex items-center gap-3 px-4 py-3 text-sm font-medium rounded-lg transition-colors #{if @active, do: "bg-purple-50 text-purple-700", else: "text-gray-600 hover:bg-gray-50 hover:text-gray-900"}"}
    >
      <.icon name={@icon} class="w-5 h-5 shrink-0" />
      <span>{@label}</span>
    </button>
    """
  end
end
