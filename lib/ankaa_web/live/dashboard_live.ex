defmodule AnkaaWeb.DashboardLive do
  use AnkaaWeb, :live_view
  alias Ankaa.Redis

  @moduledoc """
  LiveView dashboard to display real-time BP and dialysis data.
  """

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Ankaa.PubSub, "bp_readings")
      Phoenix.PubSub.subscribe(Ankaa.PubSub, "dialysis_readings")
      IO.puts("LiveView subscribed to Phoenix PubSub channels.")
    end

    {:ok, assign(socket, bp_data: nil, dialysis_data: nil)}
  end

  def handle_info({:redix_pubsub, :message, payload}, socket) do
    case Jason.decode(payload) do
      {:ok, %{"systolic" => _, "diastolic" => _, "heart_rate" => _} = bp_data} ->
        IO.puts("Received BP data in LiveView: #{payload}")
        {:noreply, assign(socket, bp_data: bp_data)}

      {:ok, %{"fluid_level" => _, "flow_rate" => _, "clot_detected" => _} = dialysis_data} ->
        IO.puts("Received Dialysis data in LiveView: #{payload}")
        {:noreply, assign(socket, dialysis_data: dialysis_data)}

      _ ->
        IO.puts("Received unknown message: #{payload}")
        {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="p-8 bg-gray-100 min-h-screen">
      <h1 class="text-3xl font-bold mb-8">Real-Time Dialysis & BP Monitoring</h1>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
        <!-- Blood Pressure Section -->
        <div class="bg-white p-6 rounded-lg shadow-md">
          <h2 class="text-2xl font-semibold mb-4">Blood Pressure</h2>
          <p class="text-lg"><strong>Systolic:</strong> <%= @bp_data["systolic"] || "Waiting for data..." %></p>
          <p class="text-lg"><strong>Diastolic:</strong> <%= @bp_data["diastolic"] || "Waiting for data..." %></p>
          <p class="text-lg"><strong>Heart Rate:</strong> <%= @bp_data["heart_rate"] || "Waiting for data..." %></p>
          <p class="text-md text-gray-500">Last updated: <%= @bp_data["timestamp"] || "N/A" %></p>
        </div>

        <!-- Dialysis Metrics Section -->
        <div class="bg-white p-6 rounded-lg shadow-md">
          <h2 class="text-2xl font-semibold mb-4">Dialysis Metrics</h2>
          <p class="text-lg"><strong>Fluid Level:</strong> <%= @dialysis_data["fluid_level"] || "Waiting for data..." %></p>
          <p class="text-lg"><strong>Flow Rate:</strong> <%= @dialysis_data["flow_rate"] || "Waiting for data..." %></p>
          <p class="text-lg"><strong>Clot Detected:</strong> <%= @dialysis_data["clot_detected"] || "Waiting for data..." %></p>
          <p class="text-md text-gray-500">Last updated: <%= @dialysis_data["timestamp"] || "N/A" %></p>
        </div>
      </div>
    </div>
    """
  end
end
