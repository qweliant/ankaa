defmodule AnkaaWeb.AppNav do
  @moduledoc """
  Navigation component for the main application layout.
  """
  use AnkaaWeb, :live_component

  def render(assigns) do
    ~H"""
    <nav class="bg-white border-b border-gray-200 fixed w-full z-30 top-0 start-0">
      <div class="max-w-7xl flex flex-wrap items-center justify-between mx-auto p-4">

        <a href="/" class="flex items-center space-x-3 rtl:space-x-reverse">
          <div class="h-8 w-8 bg-purple-600 rounded-lg flex items-center justify-center text-white font-bold">A</div>
          <span class="self-center text-2xl font-semibold whitespace-nowrap text-gray-900">Ankaa</span>
        </a>

        <button data-collapse-toggle="navbar-default" type="button" class="inline-flex items-center p-2 w-10 h-10 justify-center text-sm text-gray-500 rounded-lg md:hidden hover:bg-gray-100" aria-controls="navbar-default" aria-expanded="false">
          <span class="sr-only">Open main menu</span>
          <.icon name="hero-bars-3" class="w-5 h-5"/>
        </button>

        <div class="hidden w-full md:block md:w-auto" id="navbar-default">
          <ul class="font-medium flex flex-col p-4 md:p-0 mt-4 border border-gray-100 rounded-lg bg-gray-50 md:flex-row md:space-x-8 rtl:space-x-reverse md:mt-0 md:border-0 md:bg-white">
            <%= for {label, path, icon} <- menu_items(@current_user) do %>
              <li>
                <.link navigate={path} class="block py-2 px-3 text-gray-900 rounded-sm hover:bg-gray-100 md:hover:bg-transparent md:border-0 md:hover:text-purple-700 md:p-0 items-center">
                  <.icon name={icon} class="w-5 h-5 mr-2 text-gray-400 group-hover:text-purple-600" />
                  {label}
                </.link>
              </li>
            <% end %>
          </ul>
        </div>
      </div>
    </nav>
    """
  end

  defp menu_items(user) do
    base_links = []

    role_links = case user.role do
      role when role in ["doctor", "nurse", "clinic_technician"] ->
        [
          {"Patients", ~p"/careprovider/patients", "hero-users"},
          {"Community Hub", ~p"/community/dashboard", "hero-building-office-2"}
        ]

      "social_worker" ->
        [
          {"Caseload", ~p"/case/dashboard", "hero-clipboard-document-list"},
          {"Community Hub", ~p"/community/dashboard", "hero-building-office-2"}
        ]

      "community_coordinator" ->
        [
          {"Members", ~p"/community/members", "hero-user-group"},
          {"Community Hub", ~p"/community/dashboard", "hero-megaphone"}
        ]

      _ ->
          []
    end

    base_links ++ role_links
  end
end
