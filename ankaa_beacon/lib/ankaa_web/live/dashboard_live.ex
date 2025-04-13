defmodule AnkaaWeb.DashboardLive do
  use AnkaaWeb, :live_view
  alias Ankaa.Monitoring.{BPReadings, DialysisReadings, BPDeviceReading, DialysisDeviceReading}

  @moduledoc """
  LiveView dashboard to display real-time BP and dialysis data.
  """

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to PubSub topics
      Phoenix.PubSub.subscribe(Ankaa.PubSub, "dialysisdevicereading_readings")
      Phoenix.PubSub.subscribe(Ankaa.PubSub, "bpdevicereading_readings")
    end

    # Get initial readings
    bp_readings = BPReadings.list_bp_readings(limit: 10)
    dialysis_readings = DialysisReadings.list_dialysis_readings(limit: 10)

    socket =
      socket
      |> assign(:bp_readings, bp_readings)
      |> assign(:dialysis_readings, dialysis_readings)
      |> assign(:page_title, "Dashboard")
      |> assign(:bp_violations, [])
      |> assign(:dialysis_violations, [])
      |> assign(:active_tab, :overview)

    {:ok, socket}
  end

  @impl true
  def handle_info({:new_reading, reading, violations}, socket) do
    case reading do
      %BPDeviceReading{} = bp_reading ->
        # Update blood pressure readings and violations
        bp_readings = [bp_reading | socket.assigns.bp_readings] |> Enum.take(10)

        socket =
          socket
          |> assign(:bp_readings, bp_readings)
          |> assign(:bp_violations, violations)

        {:noreply, socket}

      %DialysisDeviceReading{} = dialysis_reading ->
        # Update dialysis readings and violations
        dialysis_readings = [dialysis_reading | socket.assigns.dialysis_readings] |> Enum.take(10)

        socket =
          socket
          |> assign(:dialysis_readings, dialysis_readings)
          |> assign(:dialysis_violations, violations)

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, String.to_existing_atom(tab))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <!-- Header -->
      <header class="bg-white shadow">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div class="flex justify-between items-center">
            <h1 class="text-2xl font-bold text-gray-900">Patient Monitoring Dashboard</h1>
            <div class="flex items-center space-x-4">
              <span class="text-sm text-gray-500">Last updated: <%= format_datetime(DateTime.utc_now()) %></span>
            </div>
          </div>
        </div>
      </header>

      <!-- Main Content -->
      <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <!-- Alert Banner -->
        <%= if @bp_violations != [] or @dialysis_violations != [] do %>
          <div class="mb-6">
            <div class="bg-red-50 border-l-4 border-red-400 p-4">
              <div class="flex">
                <div class="flex-shrink-0">
                  <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
                  </svg>
                </div>
                <div class="ml-3">
                  <h3 class="text-sm font-medium text-red-800">Active Alerts</h3>
                  <div class="mt-2 text-sm text-red-700">
                    <ul class="list-disc pl-5 space-y-1">
                      <%= for violation <- @bp_violations do %>
                        <li><%= violation.message %></li>
                      <% end %>
                      <%= for violation <- @dialysis_violations do %>
                        <li><%= violation.message %></li>
                      <% end %>
                    </ul>
                  </div>
                </div>
              </div>
            </div>
          </div>
        <% end %>

        <!-- Tabs -->
        <div class="mb-6">
          <div class="border-b border-gray-200">
            <nav class="-mb-px flex space-x-8">
              <button
                phx-click="switch_tab"
                phx-value-tab="overview"
                class={[
                  "whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm",
                  if @active_tab == :overview do
                    "border-indigo-500 text-indigo-600"
                  else
                    "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
                  end
                ]}
              >
                Overview
              </button>
              <button
                phx-click="switch_tab"
                phx-value-tab="blood_pressure"
                class={[
                  "whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm",
                  if @active_tab == :blood_pressure do
                    "border-indigo-500 text-indigo-600"
                  else
                    "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
                  end
                ]}
              >
                Blood Pressure
              </button>
              <button
                phx-click="switch_tab"
                phx-value-tab="dialysis"
                class={[
                  "whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm",
                  if @active_tab == :dialysis do
                    "border-indigo-500 text-indigo-600"
                  else
                    "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
                  end
                ]}
              >
                Dialysis
              </button>
            </nav>
          </div>
        </div>

        <!-- Content -->
        <div class="bg-white shadow rounded-lg">
          <%= case @active_tab do %>
            <% :overview -> %>
              <div class="p-6">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <!-- Blood Pressure Summary -->
                  <div class="bg-white rounded-lg border border-gray-200 p-6">
                    <h3 class="text-lg font-medium text-gray-900 mb-4">Blood Pressure Summary</h3>
                    <%= if @bp_readings == [] do %>
                      <div class="text-center text-gray-500 py-4">No blood pressure readings available</div>
                    <% else %>
                      <div class="space-y-4">
                        <%= for reading <- Enum.take(@bp_readings, 1) do %>
                          <div class="flex items-center justify-between">
                            <div class="flex items-center">
                              <div class="text-3xl font-bold text-gray-900">
                                <%= reading.systolic %>/<%= reading.diastolic %>
                              </div>
                              <div class="ml-4">
                                <div class="text-sm text-gray-500">mmHg</div>
                                <div class="text-sm text-gray-500">Heart Rate: <%= reading.heart_rate %> BPM</div>
                              </div>
                            </div>
                            <div class={["px-3 py-1 rounded-full text-sm font-medium", bp_status_class(reading)]}>
                              <%= bp_status(reading) %>
                            </div>
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                  </div>

                  <!-- Dialysis Summary -->
                  <div class="bg-white rounded-lg border border-gray-200 p-6">
                    <h3 class="text-lg font-medium text-gray-900 mb-4">Dialysis Summary</h3>
                    <%= if @dialysis_readings == [] do %>
                      <div class="text-center text-gray-500 py-4">No dialysis readings available</div>
                    <% else %>
                      <div class="space-y-4">
                        <%= for reading <- Enum.take(@dialysis_readings, 1) do %>
                          <div class="flex items-center justify-between">
                            <div>
                              <div class="text-lg font-medium text-gray-900"><%= reading.mode %></div>
                              <div class="text-sm text-gray-500">Time in Treatment: <%= reading.time_in_treatment %> min</div>
                              <div class="text-sm text-gray-500">Time Remaining: <%= reading.time_remaining %> min</div>
                            </div>
                            <div class={["px-3 py-1 rounded-full text-sm font-medium", dialysis_status_class(reading)]}>
                              <%= dialysis_status(reading) %>
                            </div>
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>

            <% :blood_pressure -> %>
              <div class="p-6">
                <h3 class="text-lg font-medium text-gray-900 mb-4">Blood Pressure Readings</h3>
                <%= if @bp_readings == [] do %>
                  <div class="text-center text-gray-500 py-4">No blood pressure readings available</div>
                <% else %>
                  <div class="space-y-4">
                    <%= for reading <- @bp_readings do %>
                      <div class={"border rounded-lg p-4 #{if reading.status == "critical", do: "border-red-400 bg-red-50", else: ""}"}>
                        <div class="flex justify-between items-start">
                          <div>
                            <div class="flex items-center space-x-4">
                              <div class="text-2xl font-bold text-gray-900">
                                <%= reading.systolic %>/<%= reading.diastolic %>
                              </div>
                              <div class="text-sm text-gray-500">mmHg</div>
                            </div>
                            <div class="mt-2 grid grid-cols-2 gap-4">
                              <div>
                                <div class="text-sm text-gray-500">Heart Rate</div>
                                <div class="text-lg font-medium"><%= reading.heart_rate %> BPM</div>
                              </div>
                              <div>
                                <div class="text-sm text-gray-500">MAP</div>
                                <div class="text-lg font-medium"><%= reading.mean_arterial_pressure %> mmHg</div>
                              </div>
                              <div>
                                <div class="text-sm text-gray-500">Pulse Pressure</div>
                                <div class="text-lg font-medium"><%= reading.pulse_pressure %> mmHg</div>
                              </div>
                              <div>
                                <div class="text-sm text-gray-500">Irregular Heartbeat</div>
                                <div class="text-lg font-medium"><%= if reading.irregular_heartbeat, do: "Yes", else: "No" %></div>
                              </div>
                            </div>
                          </div>
                          <div class="flex flex-col items-end">
                            <div class={["px-3 py-1 rounded-full text-sm font-medium", bp_status_class(reading)]}>
                              <%= bp_status(reading) %>
                            </div>
                            <div class="mt-2 text-sm text-gray-500">
                              <%= format_datetime(reading.timestamp) %>
                            </div>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>

            <% :dialysis -> %>
              <div class="p-6">
                <h3 class="text-lg font-medium text-gray-900 mb-4">Dialysis Readings</h3>
                <%= if @dialysis_readings == [] do %>
                  <div class="text-center text-gray-500 py-4">No dialysis readings available</div>
                <% else %>
                  <div class="space-y-4">
                    <%= for reading <- @dialysis_readings do %>
                      <div class={"border rounded-lg p-4 #{if reading.status == "critical", do: "border-red-400 bg-red-50", else: ""}"}>
                        <div class="flex justify-between items-start">
                          <div>
                            <div class="flex items-center space-x-4">
                              <div class="text-xl font-medium text-gray-900"><%= reading.mode %></div>
                              <div class="text-sm text-gray-500">Treatment Time: <%= reading.time_in_treatment %> min</div>
                            </div>
                            <div class="mt-4 grid grid-cols-2 md:grid-cols-3 gap-4">
                              <div>
                                <div class="text-sm text-gray-500">Time Remaining</div>
                                <div class="text-lg font-medium"><%= reading.time_remaining %> min</div>
                              </div>
                              <div>
                                <div class="text-sm text-gray-500">Blood Flow</div>
                                <div class="text-lg font-medium"><%= reading.bfr %> ml/min</div>
                              </div>
                              <div>
                                <div class="text-sm text-gray-500">Dialysate Flow</div>
                                <div class="text-lg font-medium"><%= reading.dfr %> L/hr</div>
                              </div>
                              <div>
                                <div class="text-sm text-gray-500">UF Volume</div>
                                <div class="text-lg font-medium"><%= reading.ufv %> L</div>
                              </div>
                              <div>
                                <div class="text-sm text-gray-500">UF Rate</div>
                                <div class="text-lg font-medium"><%= reading.ufr %> L/hr</div>
                              </div>
                              <div>
                                <div class="text-sm text-gray-500">Venous Pressure</div>
                                <div class="text-lg font-medium"><%= reading.vp %> mmHg</div>
                              </div>
                            </div>
                          </div>
                          <div class="flex flex-col items-end">
                            <div class={["px-3 py-1 rounded-full text-sm font-medium", dialysis_status_class(reading)]}>
                              <%= dialysis_status(reading) %>
                            </div>
                            <div class="mt-2 text-sm text-gray-500">
                              <%= format_datetime(reading.timestamp) %>
                            </div>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
          <% end %>
        </div>
      </main>
    </div>
    """
  end

  defp format_datetime(datetime) do
    datetime
    |> DateTime.truncate(:second)
    |> DateTime.to_string()
  end

  defp bp_status_class(reading) do
    case reading.status do
      "normal" -> "bg-green-100 text-green-800"
      "warning" -> "bg-yellow-100 text-yellow-800"
      "critical" -> "bg-red-100 text-red-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp bp_status(reading) do
    case reading.status do
      "normal" -> "Normal"
      "warning" -> "Warning"
      "critical" -> "Critical"
      _ -> "Unknown"
    end
  end

  defp dialysis_status_class(reading) do
    case reading.status do
      "normal" -> "bg-green-100 text-green-800"
      "warning" -> "bg-yellow-100 text-yellow-800"
      "critical" -> "bg-red-100 text-red-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp dialysis_status(reading) do
    case reading.status do
      "normal" -> "Normal"
      "warning" -> "Warning"
      "critical" -> "Critical"
      _ -> "Unknown"
    end
  end
end
