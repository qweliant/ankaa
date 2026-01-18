defmodule AnkaaWeb.PatientDashboard.Components.MonitoringComponent do
  @moduledoc """
  Handles the live monitoring UI: Session controls, MQTT commands, and Chart display.
  Real-time data is passed in from the Parent LiveView via assigns.
  """
  use AnkaaWeb, :live_component

  alias Ankaa.Sessions
  alias Ankaa.MQTT

  @impl true
  def update(assigns, socket) do
    # Check if a session is currently running in the DB
    active_session = Sessions.get_active_session_for_patient(assigns.patient.id)

    socket =
      socket
      |> assign(assigns)
      # Defaults
      |> assign_new(:active_tab, fn -> :blood_pressure end)
      # Session State
      |> assign(:active_session, active_session)
      |> assign(:session_started, active_session != nil)
      |> assign(:session_start_time, if(active_session, do: active_session.start_time, else: nil))

    {:ok, socket}
  end

  # --- TABS ---
  @impl true
  def handle_event("switch_monitor_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: String.to_existing_atom(tab))}
  end

  # --- SESSION CONTROL ---
  @impl true
  def handle_event("start_session", _, socket) do
    patient = socket.assigns.patient
    current_time = DateTime.utc_now()

    # 1. Create Database Record
    case Sessions.create_session(%{
           start_time: current_time,
           patient_id: patient.id,
           status: "ongoing"
         }) do
      {:ok, session} ->
        # 2. Trigger Simulation via MQTT
        devices = socket.assigns.devices

        # Build payload for the simulator
        command_payload =
          Enum.map(devices, fn device ->
            %{
              device_id: device.id,
              # Assuming scenario is stored as "HighSystolic", etc.
              scenario: Macro.underscore(device.simulation_scenario || "Normal"),
              device_type: map_device_type(device.type)
            }
          end)

        MQTT.publish("ankaa/simulator/control", Jason.encode!(%{start_simulations: command_payload}))

        # 3. Alerting (Optional: You can add Alerts.create_alert here if desired)

        {:noreply,
         assign(socket,
           session_started: true,
           active_session: session,
           session_start_time: session.start_time
         )}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not start session.")}
    end
  end

  @impl true
  def handle_event("end_session", _, socket) do
    # 1. Stop Simulation
    devices = socket.assigns.devices
    # Extract IDs to tell simulator which ones to stop
    stop_payload = %{stop_simulations: Enum.map(devices, & &1.id)}
    MQTT.publish("ankaa/simulator/control", Jason.encode!(stop_payload))

    # 2. End Database Record
    if socket.assigns.active_session do
      Sessions.end_session(socket.assigns.active_session)
    end

    {:noreply,
     assign(socket,
       session_started: false,
       active_session: nil,
       session_start_time: nil
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto space-y-6">

      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <h2 class="text-2xl font-bold text-slate-800">Live Monitoring</h2>

        <div class="flex items-center space-x-4 bg-white px-4 py-2 rounded-full shadow-sm border border-slate-100 text-sm">
          <div class="flex items-center">
            <div class="h-2.5 w-2.5 rounded-full bg-emerald-500 mr-2"></div>
            <span class="text-slate-600">Normal</span>
          </div>
          <div class="flex items-center">
            <div class="h-2.5 w-2.5 rounded-full bg-amber-500 mr-2"></div>
            <span class="text-slate-600">Warning</span>
          </div>
          <div class="flex items-center">
            <div class="h-2.5 w-2.5 rounded-full bg-rose-500 mr-2"></div>
            <span class="text-slate-600">Critical</span>
          </div>
        </div>
      </div>

      <%= if @session_started do %>
        <div class="bg-indigo-900 rounded-3xl p-6 sm:p-8 text-white shadow-xl shadow-indigo-900/20 relative overflow-hidden">
          <div class="absolute top-0 right-0 -mt-10 -mr-10 w-64 h-64 bg-white opacity-5 rounded-full blur-3xl"></div>

          <div class="relative z-10 flex flex-col md:flex-row items-center justify-between gap-6">
            <div class="text-center md:text-left">
              <div class="flex items-center justify-center md:justify-start gap-2 mb-2">
                <span class="relative flex h-3 w-3">
                  <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                  <span class="relative inline-flex rounded-full h-3 w-3 bg-emerald-500"></span>
                </span>
                <p class="text-indigo-200 text-sm font-bold uppercase tracking-wider">Session In Progress</p>
              </div>
              <div class="text-5xl font-mono font-bold tracking-tight">
                <span phx-hook="SessionTimer" id="session-timer" data-start-time={DateTime.to_iso8601(@session_start_time)}>
                  00:00:00
                </span>
              </div>
            </div>

            <button
              phx-click="end_session"
              phx-target={@myself}
              data-confirm="Are you sure you want to end the session?"
              class="bg-white text-indigo-900 hover:bg-indigo-50 px-8 py-4 rounded-xl font-bold transition shadow-lg flex items-center gap-2 group"
            >
              <div class="w-2 h-2 bg-rose-500 rounded-sm group-hover:scale-110 transition-transform"></div>
              End Session
            </button>
          </div>
        </div>

        <div class="bg-white rounded-3xl shadow-sm border border-slate-200 overflow-hidden">
          <div class="border-b border-slate-200 flex">
            <button
              phx-click="switch_monitor_tab"
              phx-value-tab="blood_pressure"
              phx-target={@myself}
              class={"flex-1 py-4 font-bold text-sm transition relative #{
                if @active_tab == :blood_pressure,
                do: "text-indigo-600",
                else: "text-slate-500 hover:text-slate-700 bg-slate-50"
              }"}
            >
              Blood Pressure
              <%= if @active_tab == :blood_pressure do %>
                <div class="absolute bottom-0 left-0 right-0 h-1 bg-indigo-600 rounded-t-full mx-12"></div>
              <% end %>
            </button>
            <button
              phx-click="switch_monitor_tab"
              phx-value-tab="dialysis"
              phx-target={@myself}
              class={"flex-1 py-4 font-bold text-sm transition relative #{
                if @active_tab == :dialysis,
                do: "text-indigo-600",
                else: "text-slate-500 hover:text-slate-700 bg-slate-50"
              }"}
            >
              Dialysis Machine
              <%= if @active_tab == :dialysis do %>
                <div class="absolute bottom-0 left-0 right-0 h-1 bg-indigo-600 rounded-t-full mx-12"></div>
              <% end %>
            </button>
          </div>

          <div class="p-6">
            <%= case @active_tab do %>
              <% :blood_pressure -> %>
                <.live_component
                   module={AnkaaWeb.Monitoring.BPComponent}
                   id="bp-chart"
                   latest={@bp_readings |> List.first()}
                   readings={@bp_readings}
                   devices={@devices}
                />

              <% :dialysis -> %>
                <.live_component
                   module={AnkaaWeb.Monitoring.DialysisComponent}
                   id="dialysis-chart"
                   latest={@dialysis_readings |> List.first()}
                   readings={@dialysis_readings}
                   devices={@devices}
                />
            <% end %>
          </div>
        </div>

      <% else %>
        <div class="bg-white rounded-3xl p-12 text-center border-2 border-dashed border-slate-200 hover:border-indigo-200 transition-colors group">
           <div class="w-24 h-24 bg-indigo-50 text-indigo-600 rounded-full flex items-center justify-center mx-auto mb-6 group-hover:scale-110 transition-transform duration-300">
             <.icon name="hero-play" class="w-12 h-12 ml-1" />
           </div>
           <h3 class="text-2xl font-bold text-slate-900 mb-2">Ready to start?</h3>
           <p class="text-slate-500 mb-8 max-w-md mx-auto">
             Ensure your blood pressure cuff and dialysis machine are connected. Starting a session will notify your care team.
           </p>
           <button
             phx-click="start_session"
             phx-target={@myself}
             class="bg-indigo-600 hover:bg-indigo-700 text-white px-10 py-5 rounded-2xl font-bold text-lg shadow-xl shadow-indigo-200 transition transform hover:-translate-y-1"
           >
             Start Dialysis Session
           </button>
        </div>
      <% end %>

    </div>
    """
  end

  # Helper for MQTT mapping
  defp map_device_type("blood_pressure"), do: "bp"
  defp map_device_type("dialysis"), do: "dialysis"
  defp map_device_type(_), do: "bp"
end
