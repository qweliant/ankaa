defmodule AnkaaWeb.DashboardLive.Index do
  use AnkaaWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-3xl">
        <h1 class="text-2xl font-semibold leading-tight">Dashboard</h1>
        <div class="mt-4">
          <p>Welcome to your dashboard!</p>
        </div>
      </div>
    </div>
    """
  end
end
