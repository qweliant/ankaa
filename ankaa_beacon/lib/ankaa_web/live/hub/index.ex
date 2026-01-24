defmodule AnkaaWeb.PortalLive.Index do
  use AnkaaWeb, :live_view

  alias Ankaa.Patients
  alias Ankaa.Communities

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    communities = Communities.list_organizations_for_user(user)
    my_patient_profile = Patients.get_patient_by_user_id(user.id)

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
       my_patient_profile: my_patient_profile
     )}
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
          <p class="mt-1 text-sm text-gray-500">
            Select a dashboard to view.
          </p>
        </div>
      </div>

      <%= if @my_patient_profile do %>
        <div class="mb-12">
          <h3 class="text-lg font-medium leading-6 text-gray-900 mb-4">My Health</h3>
          <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            <.link
              navigate={~p"/p/#{@my_patient_profile.id}/dashboard"}
              class="group relative flex items-center gap-x-6 rounded-lg p-4 text-sm leading-6 hover:bg-gray-50 border border-gray-200 bg-white shadow-sm"
            >
              <div class="flex h-11 w-11 flex-none items-center justify-center rounded-lg bg-red-50 group-hover:bg-red-100">
                <.icon name="hero-heart" class="h-6 w-6 text-red-600 group-hover:text-red-700" />
              </div>
              <div class="flex-auto">
                <span class="block font-semibold text-gray-900">
                  My Dashboard <span class="absolute inset-0"></span>
                </span>
                <p class="mt-1 text-gray-600">View your vitals, alerts, and care plan.</p>
              </div>
            </.link>
          </div>
        </div>
      <% end %>

      <%= if not Enum.empty?(@care_networks) do %>
        <div class="mb-12">
          <h3 class="text-lg font-medium leading-6 text-gray-900 mb-4">Care Networks</h3>
          <ul role="list" class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            <%= for patient <- @care_networks do %>
              <li class="col-span-1 divide-y divide-gray-200 rounded-lg bg-white shadow border border-gray-100 transition hover:shadow-md">
                <.link navigate={~p"/p/#{patient.id}/dashboard"} class="block">
                  <div class="flex w-full items-center justify-between space-x-6 p-6">
                    <div class="flex-1 truncate">
                      <div class="flex items-center space-x-3">
                        <h3 class="truncate text-sm font-medium text-gray-900">{patient.name}</h3>
                        <span class="inline-flex shrink-0 items-center rounded-full bg-green-50 px-1.5 py-0.5 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20">
                          Active
                        </span>
                      </div>
                      <p class="mt-1 truncate text-sm text-gray-500">Patient Dashboard</p>
                    </div>
                    <div class="h-10 w-10 shrink-0 rounded-full bg-blue-100 flex items-center justify-center">
                      <.icon name="hero-user" class="h-6 w-6 text-blue-600" />
                    </div>
                  </div>
                </.link>
              </li>
            <% end %>
          </ul>
        </div>
      <% end %>

      <div>
        <h3 class="text-lg font-medium leading-6 text-gray-900 mb-4">My Communities</h3>

        <%= if Enum.empty?(@communities) do %>
          <div class="text-sm text-gray-500 italic">
            You are not a member of any communities yet.
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
    </div>
    """
  end
end
