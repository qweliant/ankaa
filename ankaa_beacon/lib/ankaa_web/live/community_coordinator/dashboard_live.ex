defmodule AnkaaWeb.Community.DashboardLive do
  use AnkaaWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-10">
      <.header>
        Community Dashboard
        <:subtitle>Welcome, Community Coordinator.</:subtitle>
      </.header>

      <div class="mt-8 bg-white shadow sm:rounded-lg">
        <div class="px-4 py-5 sm:p-6">
          <h3 class="text-base font-semibold leading-6 text-gray-900">Community Management</h3>
          <div class="mt-2 max-w-xl text-sm text-gray-500">
            <p>This is the placeholder for the Community Coordinator dashboard.</p>
            <p class="mt-2">Planned features:</p>
            <ul class="list-disc pl-5 mt-1">
              <li>Manage Patient Support Groups</li>
              <li>Post Community Announcements</li>
              <li>Resource Sharing Board</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
