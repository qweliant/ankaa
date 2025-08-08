defmodule AnkaaWeb.MonitoringLive do
  use AnkaaWeb, :patient_layout
  use AnkaaWeb, :alert_handling

  alias Ankaa.Patients
  alias Ankaa.Alerts
  alias Ankaa.Sessions

  @moduledoc """
  LiveView dashboard to display real-time BP and dialysis data.
  """

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Ankaa.PubSub, "bpdevicereading_readings")
      Phoenix.PubSub.subscribe(Ankaa.PubSub, "dialysisdevicereading_readings")
      Phoenix.PubSub.subscribe(Ankaa.PubSub, "user:#{socket.assigns.current_user.id}:alerts")
    end

    # Get patient's registered devices
    devices = Patients.list_devices_for_patient(socket.assigns.current_user.patient.id)

    case Sessions.get_active_session_for_patient(socket.assigns.current_user.patient.id) do
      nil ->
        {:ok,
         assign(socket,
           active_tab: :blood_pressure,
           bp_readings: [],
           dialysis_readings: [],
           devices: devices,
           current_path: "/patient/monitoring",
           session_started: false,
           session_start_time: nil,
           active_session: nil
         )}

      session ->
        {:ok,
         assign(socket,
           active_tab: :blood_pressure,
           bp_readings: [],
           dialysis_readings: [],
           devices: devices,
           current_path: "/patient/monitoring",
           session_started: true,
           session_start_time: session.start_time,
           active_session: session
         )}
    end
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: String.to_existing_atom(tab))}
  end

  @impl true
  def handle_event("start_session", _params, socket) do
    patient = socket.assigns.current_user.patient
    current_time = DateTime.utc_now()

    case Sessions.create_session(%{
           start_time: current_time,
           patient_id: patient.id,
           status: "ongoing"
         }) do
      {:ok, session} ->
        alert_attrs = %{
          patient_id: patient.id,
          type: "session_start",
          severity: "info",
          message:
            "💙 #{patient.name} just started their dialysis session. (Started at #{DateTime.to_time(current_time) |> Calendar.strftime("%I:%M:%S %p")})"
        }

        Alerts.create_alert(alert_attrs)

        {:noreply,
         assign(socket,
           session_started: true,
           session_start_time: session.start_time,
           active_session: session
         )}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to start session.")}
    end
  end

  @impl true
  def handle_event("end_session", _params, socket) do
    patient_name = socket.assigns.current_user.patient.name || "Your patient"
    patient_id = socket.assigns.current_user.patient.id

    case socket.assigns.active_session do
      nil ->
        {:noreply, put_flash(socket, :error, "No active session to end.")}

      session ->
        case Sessions.end_session(session) do
          {:ok, ended_session} ->
            duration_in_minutes =
              Timex.diff(ended_session.end_time, ended_session.start_time, :minutes)

            alert_message =
              "✅ #{patient_name}'s session ended successfully after #{duration_in_minutes} minutes."

            {:ok, alert} =
              Ankaa.Alerts.create_alert(%{
                type: "Session",
                message: alert_message,
                patient_id: patient_id,
                severity: "info"
              })

            Phoenix.PubSub.broadcast(
              Ankaa.PubSub,
              "patient:#{patient_id}:alerts",
              {:new_alert, alert}
            )

            socket =
              put_flash(
                socket,
                :info,
                "Session ended successfully."
              )

            {:noreply,
             assign(socket,
               session_started: false,
               session_start_time: nil,
               active_session: nil
             )}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to end session.")}
        end
    end
  end

  @impl true
  def handle_info({:new_reading, reading, violations}, socket)
      when is_map_key(reading, :systolic) do
    # Only process readings from registered devices
    if Enum.any?(socket.assigns.devices, &(&1.device_id == reading.device_id)) do
      {:noreply,
       socket
       |> update(:bp_readings, fn readings -> [reading | Enum.take(readings, 9)] end)
       |> update(:bp_violations, fn _ -> violations end)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:new_reading, reading, violations}, socket) when is_map_key(reading, :bfr) do
    # Only process readings from registered devices
    if Enum.any?(socket.assigns.devices, &(&1.device_id == reading.device_id)) do
      {:noreply,
       socket
       |> update(:dialysis_readings, fn readings -> [reading | Enum.take(readings, 9)] end)
       |> update(:dialysis_violations, fn _ -> violations end)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:new_alert, alert}, socket) do
    # This will receive the session start alert we just created
    # For now, we'll just log it, but you could show additional UI feedback
    require Logger
    Logger.info("Patient received alert confirmation: #{alert.message}")
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="flex items-center justify-between mb-8">
        <h1 class="text-2xl font-bold text-slate-900">Patient Monitoring</h1>
        <div class="flex items-center space-x-4">
          <div class="flex items-center">
            <div class="h-3 w-3 rounded-full bg-emerald-500 mr-2"></div>
            <span class="text-sm text-slate-600">Normal</span>
          </div>
          <div class="flex items-center">
            <div class="h-3 w-3 rounded-full bg-amber-500 mr-2"></div>
            <span class="text-sm text-slate-600">Warning</span>
          </div>
          <div class="flex items-center">
            <div class="h-3 w-3 rounded-full bg-rose-500 mr-2"></div>
            <span class="text-sm text-slate-600">Critical</span>
          </div>
        </div>
      </div>

      <!-- Start Dialysis Session Button -->
    <%= if @session_started do %>
        <div class="bg-white shadow rounded-lg p-6 mb-8 flex flex-col items-center justify-center text-center">
          <h2 class="text-lg font-medium text-gray-900 mb-2">Session in Progress</h2>
          <p class="text-sm text-gray-500 mb-4">
            Your care team has been notified and is monitoring your session.
          </p>
          <div
            id="session-timer"
            class="text-4xl font-bold text-indigo-600 tabular-nums"
            phx-hook="SessionTimer"
            data-start-time={DateTime.to_iso8601(@session_start_time)}
          >
            00:00:00
          </div>
        <button
          phx-click="end_session"
          class="inline-flex items-center px-6 py-3 border border-transparent text-base font-semibold rounded-md shadow-sm text-white bg-rose-600 hover:bg-rose-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-rose-500 transition"
        >
          End Session
        </button>
        </div>
      <% else %>
        <div class="bg-white shadow rounded-lg p-6 mb-8 flex flex-col items-center justify-center">
          <h2 class="text-lg font-medium text-gray-900 mb-4">Ready to Start Your Dialysis Session?</h2>
          <p class="text-sm text-gray-500 mb-6 text-center">
            Notify your care team that you are beginning a new dialysis session.
          </p>
          <button
            phx-click="start_session"
            class="inline-flex items-center px-6 py-3 border border-transparent text-base font-semibold rounded-md shadow-sm text-white bg-emerald-600 hover:bg-emerald-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-emerald-500 transition"
          >
            Start Session & Notify Care Team
          </button>
        </div>
      <% end %>

      <%!-- <div class="bg-white rounded-lg shadow-sm border border-slate-200 overflow-hidden">
        <div class="border-b border-slate-200">
          <nav class="flex -mb-px">
            <button
              phx-click="switch_tab"
              phx-value-tab="blood_pressure"
              class={"px-4 py-3 text-sm font-medium border-b-2 #{if @active_tab == :blood_pressure, do: "border-blue-500 text-blue-600", else: "border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300"}"}
            >
              Blood Pressure
            </button>
            <button
              phx-click="switch_tab"
              phx-value-tab="dialysis"
              class={"px-4 py-3 text-sm font-medium border-b-2 #{if @active_tab == :dialysis, do: "border-blue-500 text-blue-600", else: "border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300"}"}
            >
              Dialysis
            </button>
          </nav>
        </div>

        <div class="p-6">
          <%= case @active_tab do %>
            <% :blood_pressure -> %>
              <div class="space-y-6">
                <div class="flex justify-between items-center">
                  <h3 class="text-lg font-medium text-slate-800">Blood Pressure Monitor</h3>
                  <div class="bg-slate-50 text-slate-600 text-sm px-3 py-1 rounded-full border border-slate-200">
                    Real-time
                  </div>
                </div>

                <%= if Enum.empty?(@devices |> Enum.filter(&(&1.type == "blood_pressure"))) do %>
                  <div class="flex items-center justify-center h-96 bg-slate-50 rounded-lg border border-slate-200">
                    <div class="text-center">
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 mx-auto text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                      <p class="mt-2 text-slate-500">No blood pressure device registered</p>
                      <p class="mt-1 text-sm text-slate-400">Register a blood pressure device to see readings</p>
                    </div>
                  </div>
                <% else %>
                  <%= if @bp_readings == [] do %>
                    <div class="flex items-center justify-center h-96 bg-slate-50 rounded-lg border border-slate-200">
                      <div class="text-center">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 mx-auto text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        <p class="mt-2 text-slate-500">No blood pressure readings available</p>
                        <p class="mt-1 text-sm text-slate-400">Waiting for device data...</p>
                      </div>
                    </div>
                  <% else %>
                    <%= for reading <- Enum.take(@bp_readings, 1) do %>
                      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div class="bg-white rounded-lg border border-slate-200 p-6">
                          <div class="flex justify-between items-start mb-4">
                            <div>
                              <div class="text-sm text-slate-500 mb-1">Blood Pressure</div>
                              <div class="flex items-baseline">
                                <span class="text-5xl font-bold text-slate-800"><%= reading.systolic %>/<%= reading.diastolic %></span>
                                <span class="ml-2 text-lg text-slate-500">mmHg</span>
                              </div>
                            </div>
                            <div class={"px-3 py-1 rounded-full text-sm font-medium #{if reading.status == "normal", do: "bg-emerald-100 text-emerald-800", else: "bg-rose-100 text-rose-800"}"}>
                              <%= String.capitalize(reading.status || "Normal") %>
                            </div>
                          </div>

                          <div class="grid grid-cols-2 gap-4 mt-6">
                            <div class="bg-slate-50 rounded-lg p-4">
                              <div class="flex items-center justify-between mb-2">
                                <div class="text-sm font-medium text-slate-800">Heart Rate</div>
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-rose-500" viewBox="0 0 20 20" fill="currentColor">
                                  <path fill-rule="evenodd" d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" clip-rule="evenodd" />
                                </svg>
                              </div>
                              <div class="flex items-baseline">
                                <span class="text-3xl font-bold text-slate-800"><%= reading.heart_rate %></span>
                                <span class="ml-1 text-sm text-slate-500">BPM</span>
                              </div>
                              <div class="mt-2 text-sm text-slate-600">
                                <%= if reading.irregular_heartbeat, do: "⚠️ Irregular rhythm", else: "✓ Normal rhythm" %>
                              </div>
                            </div>

                            <div class="bg-slate-50 rounded-lg p-4">
                              <div class="flex items-center justify-between mb-2">
                                <div class="text-sm font-medium text-slate-800">Mean Arterial</div>
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-blue-500" viewBox="0 0 20 20" fill="currentColor">
                                  <path fill-rule="evenodd" d="M3.293 9.707a1 1 0 010-1.414l6-6a1 1 0 011.414 0l6 6a1 1 0 01-1.414 1.414L11 5.414V17a1 1 0 11-2 0V5.414L4.707 9.707a1 1 0 01-1.414 0z" clip-rule="evenodd" />
                                </svg>
                              </div>
                              <div class="flex items-baseline">
                                <span class="text-3xl font-bold text-slate-800"><%= reading.mean_arterial_pressure %></span>
                                <span class="ml-1 text-sm text-slate-500">mmHg</span>
                              </div>
                              <div class="mt-2 text-sm text-slate-600">
                                Pulse pressure: <%= reading.pulse_pressure %> mmHg
                              </div>
                            </div>
                          </div>

                          <div class="mt-6 p-4 bg-slate-50 rounded-lg">
                            <div class="flex items-center justify-between">
                              <div>
                                <div class="text-sm font-medium text-slate-800">Device Status</div>
                                <div class="text-sm text-slate-500 mt-1">
                                  <%= reading.device_id %> • <%= reading.mode %>
                                </div>
                              </div>
                              <div class="text-sm text-slate-500">
                                Last updated: <%= format_time(reading.timestamp) %>
                              </div>
                            </div>
                          </div>
                        </div>

                        <div class="bg-white rounded-lg border border-slate-200 p-6">
                          <h4 class="text-sm font-medium text-slate-800 mb-4">Recent Readings</h4>
                          <div class="space-y-4">
                            <%= for prev_reading <- Enum.take(@bp_readings, 5) do %>
                              <div class="p-3 bg-slate-50 rounded-lg">
                                <div class="flex items-center justify-between mb-1">
                                  <div class="flex items-baseline">
                                    <span class="text-lg font-semibold text-slate-800"><%= prev_reading.systolic %>/<%= prev_reading.diastolic %></span>
                                    <span class="ml-1 text-sm text-slate-500">mmHg</span>
                                  </div>
                                  <div class={"px-2 py-1 rounded-full text-xs font-medium #{if prev_reading.status == "normal", do: "bg-emerald-100 text-emerald-800", else: "bg-rose-100 text-rose-800"}"}>
                                    <%= String.capitalize(prev_reading.status || "Normal") %>
                                  </div>
                                </div>
                                <div class="flex items-center justify-between text-sm text-slate-500">
                                  <div>HR: <%= prev_reading.heart_rate %> BPM • MAP: <%= prev_reading.mean_arterial_pressure %> mmHg</div>
                                  <div><%= format_time(prev_reading.timestamp) %></div>
                                </div>
                              </div>
                            <% end %>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  <% end %>
                <% end %>
              </div>

            <% :dialysis -> %>
              <div class="space-y-6">
                <div class="flex justify-between items-center">
                  <h3 class="text-lg font-medium text-slate-800">Dialysis Monitor</h3>
                  <div class="bg-slate-50 text-slate-600 text-sm px-3 py-1 rounded-full border border-slate-200">
                    Real-time
                  </div>
                </div>

                <%= if Enum.empty?(@devices |> Enum.filter(&(&1.type == "dialysis"))) do %>
                  <div class="flex items-center justify-center h-96 bg-slate-50 rounded-lg border border-slate-200">
                    <div class="text-center">
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 mx-auto text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                      <p class="mt-2 text-slate-500">No dialysis device registered</p>
                      <p class="mt-1 text-sm text-slate-400">Register a dialysis device to see readings</p>
                    </div>
                  </div>
                <% else %>
                  <%= if @dialysis_readings == [] do %>
                    <div class="flex items-center justify-center h-96 bg-slate-50 rounded-lg border border-slate-200">
                      <div class="text-center">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 mx-auto text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        <p class="mt-2 text-slate-500">No dialysis readings available</p>
                        <p class="mt-1 text-sm text-slate-400">Waiting for device data...</p>
                      </div>
                    </div>
                  <% else %>
                    <%= for reading <- Enum.take(@dialysis_readings, 1) do %>
                      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div class="bg-white rounded-lg border border-slate-200 p-6">
                          <div class="flex justify-between items-start mb-4">
                            <div>
                              <div class="flex items-center">
                                <span class="text-2xl font-bold text-slate-800"><%= reading.mode %></span>
                              </div>
                              <div class="flex items-center mt-1">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-slate-400 mr-1" viewBox="0 0 20 20" fill="currentColor">
                                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd" />
                                </svg>
                                <span class="text-slate-500"><%= format_time(reading.timestamp) %></span>
                              </div>
                            </div>
                            <div class={"px-3 py-1 rounded-full text-sm font-medium #{if reading.status == "normal", do: "bg-emerald-100 text-emerald-800", else: "bg-rose-100 text-rose-800"}"}>
                              <%= String.capitalize(reading.status || "Unknown") %>
                            </div>
                          </div>
                          <div class="grid grid-cols-2 gap-4">
                            <div class="bg-slate-50 rounded-lg p-4">
                              <div class="text-xs text-slate-500 mb-1">Time in Treatment</div>
                              <div class="flex items-center">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-purple-500 mr-1" viewBox="0 0 20 20" fill="currentColor">
                                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd" />
                                </svg>
                                <span class="text-xl font-semibold text-slate-800"><%= reading.time_in_treatment %></span>
                                <span class="ml-1 text-slate-500">min</span>
                              </div>
                            </div>
                            <div class="bg-slate-50 rounded-lg p-4">
                              <div class="text-xs text-slate-500 mb-1">Time Remaining</div>
                              <div class="flex items-center">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-indigo-500 mr-1" viewBox="0 0 20 20" fill="currentColor">
                                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd" />
                                </svg>
                                <span class="text-xl font-semibold text-slate-800"><%= reading.time_remaining %></span>
                                <span class="ml-1 text-slate-500">min</span>
                              </div>
                            </div>
                          </div>
                          <div class="grid grid-cols-3 gap-4 mt-4">
                            <div class="bg-slate-50 rounded-lg p-4">
                              <div class="text-xs text-slate-500 mb-1">Blood Flow Rate</div>
                              <div class="flex items-center">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-orange-500 mr-1" viewBox="0 0 20 20" fill="currentColor">
                                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd" />
                                </svg>
                                <span class="text-xl font-semibold text-slate-800"><%= reading.bfr %></span>
                                <span class="ml-1 text-slate-500">ml/min</span>
                              </div>
                            </div>
                            <div class="bg-slate-50 rounded-lg p-4">
                              <div class="text-xs text-slate-500 mb-1">Dialysate Flow Rate</div>
                              <div class="flex items-center">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-violet-500 mr-1" viewBox="0 0 20 20" fill="currentColor">
                                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd" />
                                </svg>
                                <span class="text-xl font-semibold text-slate-800"><%= reading.dfr %></span>
                                <span class="ml-1 text-slate-500">L/hr</span>
                              </div>
                            </div>
                            <div class="bg-slate-50 rounded-lg p-4">
                              <div class="text-xs text-slate-500 mb-1">Venous Pressure</div>
                              <div class="flex items-center">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-slate-500 mr-1" viewBox="0 0 20 20" fill="currentColor">
                                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd" />
                                </svg>
                                <span class="text-xl font-semibold text-slate-800"><%= reading.vp %></span>
                                <span class="ml-1 text-slate-500">mmHg</span>
                              </div>
                            </div>
                          </div>
                        </div>

                        <div class="bg-white rounded-lg border border-slate-200 p-6">
                          <h4 class="text-sm font-medium text-slate-800 mb-4">Recent Readings</h4>
                          <div class="space-y-4">
                            <%= for reading <- Enum.take(@dialysis_readings, 5) do %>
                              <div class="flex items-center justify-between">
                                <div class="flex items-center">
                                  <span class="text-lg font-semibold text-slate-800"><%= reading.mode %></span>
                                  <span class="ml-2 text-sm text-slate-500"><%= reading.bfr %> ml/min</span>
                                </div>
                                <div class="text-sm text-slate-500"><%= format_time(reading.timestamp) %></div>
                              </div>
                            <% end %>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  <% end %>
                <% end %>
              </div>
          <% end %>
        </div>
      </div> --%>
    </div>
    """
  end
end
