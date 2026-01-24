defmodule AnkaaWeb.PortalLive.Index do
  use AnkaaWeb, :live_view

  alias Ankaa.Patients
  alias Ankaa.Communities

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    communities = Communities.list_organizations_for_user(user)
    my_patient_profile = Patients.get_patient_by_user_id(user.id)
    org_changeset = Communities.change_organization(%Ankaa.Community.Organization{})

    socket =
      case Patients.list_patients_for_user(user) do
        {:ok, patients} ->
          assign(socket, care_networks: patients)

        {:error, _reason} ->
          assign(socket, care_networks: [])
      end

    {:ok,
     assign(socket,
       page_title: "My Portal",
       communities: communities,
       my_patient_profile: my_patient_profile,
       show_create_org_modal: false,
       org_form: to_form(org_changeset)
     )}
  end

  @impl true
  def handle_event("toggle_create_org", _params, socket) do
    {:noreply, assign(socket, show_create_org_modal: !socket.assigns.show_create_org_modal)}
  end

  @impl true
  def handle_event("create_community", %{"organization" => org_params}, socket) do
    user = socket.assigns.current_user

    case Communities.create_organization_with_defaults(user, org_params) do
      {:ok, %{org: _org}} ->
        updated_list = Communities.list_organizations_for_user(user)

        socket =
          socket
          |> put_flash(:info, "Community created successfully!")
          |> assign(communities: updated_list, show_create_org_modal: false)

        {:noreply, socket}

      {:error, :org, changeset, _} ->
        {:noreply, assign(socket, org_form: to_form(changeset))}

      {:error, _, _, _} ->
        {:noreply, put_flash(socket, :error, "Something went wrong creating the community.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto py-12 px-4 sm:px-6 lg:px-8">
      <div class="md:flex md:items-center md:justify-between mb-10">
        <div class="min-w-0 flex-1">
          <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:truncate sm:text-3xl sm:tracking-tight">
            Welcome, {@current_user.first_name || @current_user.email}
          </h2>
        </div>
      </div>

      <div class="mb-12">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-medium leading-6 text-gray-900">My Communities</h3>
          <button phx-click="toggle_create_org" class="text-sm font-semibold text-purple-600 hover:text-purple-500">
            + Create New Community
          </button>
        </div>

        <%= if Enum.empty?(@communities) do %>
          <div class="text-center py-10 bg-slate-50 rounded-lg border-2 border-dashed border-slate-200">
            <.icon name="hero-building-office-2" class="mx-auto h-12 w-12 text-slate-300" />
            <h3 class="mt-2 text-sm font-semibold text-gray-900">No communities</h3>
            <p class="mt-1 text-sm text-gray-500">Get started by creating a new support group.</p>
            <div class="mt-6">
              <button
                phx-click="toggle_create_org"
                class="inline-flex items-center rounded-md bg-purple-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-purple-500"
              >
                <span class="hero-plus-mini -ml-0.5 mr-1.5 h-5 w-5"></span>
                New Community
              </button>
            </div>
          </div>
        <% else %>
          <ul role="list" class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            <%= for org <- @communities do %>
              <li class="col-span-1 divide-y divide-gray-200 rounded-lg bg-white shadow border border-gray-100 transition hover:shadow-md">
                <.link navigate={~p"/c/#{org.id}/dashboard"} class="block">
                  <div class="flex w-full items-center justify-between space-x-6 p-6">
                    <div class="flex-1 truncate">
                      <div class="flex items-center space-x-3">
                        <h3 class="truncate text-sm font-medium text-gray-900">{org.name}</h3>
                      </div>
                      <p class="mt-1 truncate text-sm text-gray-500">Community Hub</p>
                    </div>
                    <div class="h-10 w-10 shrink-0 rounded-full bg-purple-100 flex items-center justify-center">
                      <.icon name="hero-building-office-2" class="h-6 w-6 text-purple-600" />
                    </div>
                  </div>
                </.link>
              </li>
            <% end %>
          </ul>
        <% end %>
      </div>

      <div class="mt-16 border-t border-gray-200 pt-8">
        <h3 class="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-4">Beta Feedback & Support</h3>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
          <a href="https://forms.gle/b1mLmrXVJseidSdSA" target="_blank" class="flex items-center gap-3 p-4 rounded-lg bg-blue-50 text-blue-700 hover:bg-blue-100 transition-colors">
            <.icon name="hero-chat-bubble-bottom-center-text" class="w-6 h-6" />
            <span class="font-bold text-sm">Submit Feedback</span>
          </a>
          <a href="https://github.com/qweliant/ankaa/discussions" target="_blank" class="flex items-center gap-3 p-4 rounded-lg bg-slate-100 text-slate-700 hover:bg-slate-200 transition-colors">
            <.icon name="hero-users" class="w-6 h-6" />
            <span class="font-bold text-sm">Join Discussion</span>
          </a>
          <a href="https://github.com/qweliant/ankaa/issues" target="_blank" class="flex items-center gap-3 p-4 rounded-lg bg-slate-100 text-slate-700 hover:bg-slate-200 transition-colors">
            <.icon name="hero-bug-ant" class="w-6 h-6" />
            <span class="font-bold text-sm">Report a Bug</span>
          </a>
        </div>
      </div>

      <%= if @show_create_org_modal do %>
        <div class="relative z-50" aria-labelledby="modal-title" role="dialog" aria-modal="true">
          <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"></div>
          <div class="fixed inset-0 z-10 w-screen overflow-y-auto">
            <div class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
              <div class="relative transform overflow-hidden rounded-lg bg-white px-4 pb-4 pt-5 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg sm:p-6">

                <div class="absolute right-0 top-0 hidden pr-4 pt-4 sm:block">
                  <button phx-click="toggle_create_org" type="button" class="rounded-md bg-white text-gray-400 hover:text-gray-500">
                    <span class="sr-only">Close</span>
                    <.icon name="hero-x-mark" class="h-6 w-6" />
                  </button>
                </div>

                <div class="sm:flex sm:items-start">
                  <div class="mx-auto flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full bg-purple-100 sm:mx-0 sm:h-10 sm:w-10">
                    <.icon name="hero-building-library" class="h-6 w-6 text-purple-600" />
                  </div>
                  <div class="mt-3 text-center sm:ml-4 sm:mt-0 sm:text-left w-full">
                    <h3 class="text-base font-semibold leading-6 text-gray-900" id="modal-title">Create a Community</h3>
                    <div class="mt-2">
                      <p class="text-sm text-gray-500 mb-4">Start a new space for your clinic, neighborhood, or support group.</p>

                      <.simple_form for={@org_form} phx-submit="create_community">
                        <.input field={@org_form[:name]} label="Community Name" placeholder="e.g. Northside Dialysis Support" required />
                        <.input field={@org_form[:description]} type="textarea" label="Description" placeholder="A brief goal for this group..." />

                        <:actions>
                          <.button class="w-full">Create Community</.button>
                        </:actions>
                      </.simple_form>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      <% end %>

    </div>
    """
  end
end
