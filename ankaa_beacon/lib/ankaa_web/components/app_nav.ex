defmodule AnkaaWeb.AppNav do
  use AnkaaWeb, :live_component

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <nav class="bg-white shadow-sm">
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div class="flex h-16 justify-between">
          <div class="flex">
            <%= for {label, path, icon, module} <- menu_items(@current_user) do %>
              <div class="flex space-x-8 mr-1.5">
                <.link
                  navigate={path}
                   class={[
                  "inline-flex items-center border-b-2 px-1 pt-1 text-sm font-medium",
                  if(@socket.view == module,
                    do: "border-purple-500 text-gray-900",
                    else: "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700"
                  )
                ]}
                >
                  {label}
                </.link>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </nav>
    """
  end

  defp menu_items(nil), do: []

  defp menu_items(user) do
    role = if user.role, do: to_string(user.role), else: ""

    cond do
      role in ["clinic_technician", "doctor", "nurse"] ->
        [
          {"Patients", ~p"/careprovider/patients", "hero-users", AnkaaWeb.CareProvider.PatientsLive.Index},
          {"Community Hub", ~p"/community/dashboard", "hero-building-office-2", AnkaaWeb.Community.DashboardLive}
        ]

      role == "social_worker" ->
        [
          {"Caseload", ~p"/case/dashboard", "hero-clipboard-document-list", AnkaaWeb.SocialWorker.Index},
          {"Community Hub", ~p"/community/dashboard", "hero-building-office-2", AnkaaWeb.Community.DashboardLive}
        ]

      role == "community_coordinator" ->
        [
          {"Dashboard", ~p"/community/dashboard", "hero-chart-bar", AnkaaWeb.Community.DashboardLive},
          {"Members", ~p"/community/members", "hero-user-group", AnkaaWeb.Community.MembersLive}
        ]

      role in ["caresupport", "care_support"] ->
        [
          {"Caring For", ~p"/caresupport/caringfor", "hero-hand-holding-heart", AnkaaWeb.CaringForLive.Index}
        ]

      true ->
        []
    end
  end
end
