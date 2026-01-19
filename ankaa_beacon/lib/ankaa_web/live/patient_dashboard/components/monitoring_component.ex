defmodule AnkaaWeb.PatientDashboard.Components.MonitoringComponent do
  @moduledoc """
  Handles the live monitoring UI: Session controls, MQTT commands, and Chart display.
  Real-time data is passed in from the Parent LiveView via assigns (bp_readings list).
  """
  use AnkaaWeb, :live_component

  alias Ankaa.Sessions
  alias Ankaa.MQTT
  alias Ankaa.Alerts

  @impl true
  def update(assigns, socket) do
    # Fetch session state fresh on update (in case user swapped tabs)
    socket =
      if Map.has_key?(socket.assigns, :active_session) do
        socket
      else
        active_session = Sessions.get_active_session_for_patient(assigns.patient.id)

        assign(socket,
          active_session: active_session,
          session_started: active_session != nil,
          session_start_time: if(active_session, do: active_session.start_time, else: nil)
        )
      end

    socket =
      socket
      |> assign(assigns)
      |> assign_new(:active_tab, fn -> :blood_pressure end)

    {:ok, socket}
  end

  @impl true
  def handle_event("switch_monitor_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: String.to_existing_atom(tab))}
  end

  @impl true
  def handle_event("start_session", _, socket) do
    patient = socket.assigns.patient
    current_time = DateTime.utc_now()

    # 1. Create Session in DB
    case Sessions.create_session(%{
           start_time: current_time,
           patient_id: patient.id,
           status: "ongoing"
         }) do
      {:ok, session} ->
        # 2. Start Simulators (MQTT)
        devices = socket.assigns.devices

        command_payload =
          Enum.map(devices, fn device ->
            %{
              device_id: device.id,
              scenario: Macro.underscore(device.simulation_scenario || "Normal"),
              device_type: map_device_type(device.type)
            }
          end)

        MQTT.publish(
          "ankaa/simulator/control",
          Jason.encode!(%{start_simulations: command_payload})
        )

        # 3. Create Alert (Triggers Global Banner via PubSub)
        Alerts.create_alert(%{
          patient_id: patient.id,
          type: "session_start",
          severity: "info",
          message:
            "💙 #{patient.name} started a dialysis session at #{Calendar.strftime(current_time, "%I:%M %p")}.",
          status: "active"
        })

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
    # 1. Stop Simulators
    devices = socket.assigns.devices
    patient = socket.assigns.patient

    device_ids = Enum.map(devices, & &1.id)
    MQTT.publish("ankaa/simulator/control", Jason.encode!(%{stop_simulations: device_ids}))

    case socket.assigns.active_session do
      nil ->
        {:noreply, put_flash(socket, :error, "No active session to end.")}

      session ->
        # 2. Close Session in DB
        case Sessions.end_session(session) do
          {:ok, ended_session} ->
            # Native Elixir Diff (Minutes)
            duration = DateTime.diff(ended_session.end_time, ended_session.start_time, :minute)

            # 3. Create Completion Alert
            Alerts.create_alert(%{
              type: "Session",
              message:
                "✅ #{patient.name}'s session ended successfully after #{duration} minutes.",
              patient_id: patient.id,
              severity: "info",
              status: "active"
            })

            {:noreply,
             socket
             |> put_flash(:info, "Session ended successfully.")
             |> assign(
               session_started: false,
               session_start_time: nil,
               active_session: nil
             )}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to end session.")}
        end
    end
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
        <div class="bg-purple-900 rounded-3xl p-6 sm:p-8 text-white shadow-xl shadow-purple-900/20 relative overflow-hidden animate-fade-in">
          <div class="absolute top-0 right-0 -mt-10 -mr-10 w-64 h-64 bg-white opacity-5 rounded-full blur-3xl">
          </div>

          <div class="relative z-10 flex flex-col md:flex-row items-center justify-between gap-6">
            <div class="text-center md:text-left">
              <div class="flex items-center justify-center md:justify-start gap-2 mb-2">
                <span class="relative flex h-3 w-3">
                  <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75">
                  </span>
                  <span class="relative inline-flex rounded-full h-3 w-3 bg-emerald-500"></span>
                </span>
                <p class="text-purple-200 text-sm font-bold uppercase tracking-wider">
                  Session In Progress
                </p>
              </div>
              <div class="text-5xl font-mono font-bold tracking-tight">
                <span
                  phx-hook="SessionTimer"
                  id="session-timer"
                  data-start-time={DateTime.to_iso8601(@session_start_time)}
                >
                  00:00:00
                </span>
              </div>
            </div>

            <button
              phx-click="end_session"
              phx-target={@myself}
              data-confirm="Are you sure you want to end the session?"
              class="bg-white text-purple-900 hover:bg-purple-50 px-8 py-4 rounded-xl font-bold transition shadow-lg flex items-center gap-2 group"
            >
              <div class="w-2 h-2 bg-rose-500 rounded-sm group-hover:scale-110 transition-transform">
              </div>
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
                do: "text-purple-600 bg-white",
                else: "text-slate-500 hover:text-slate-700 bg-slate-50"
              }"}
            >
              Blood Pressure
              <%= if @active_tab == :blood_pressure do %>
                <div class="absolute bottom-0 left-0 right-0 h-0.5 bg-purple-600 rounded-t-full mx-12">
                </div>
              <% end %>
            </button>
            <button
              phx-click="switch_monitor_tab"
              phx-value-tab="dialysis"
              phx-target={@myself}
              class={"flex-1 py-4 font-bold text-sm transition relative #{
                if @active_tab == :dialysis,
                do: "text-purple-600 bg-white",
                else: "text-slate-500 hover:text-slate-700 bg-slate-50"
              }"}
            >
              Dialysis Machine
              <%= if @active_tab == :dialysis do %>
                <div class="absolute bottom-0 left-0 right-0 h-0.5 bg-purple-600 rounded-t-full mx-12">
                </div>
              <% end %>
            </button>
          </div>

          <div class="p-6">
            <%= case @active_tab do %>
              <% :blood_pressure -> %>
                <% latest_map = List.first(@bp_readings) %>
                <.live_component
                  module={AnkaaWeb.Monitoring.BPComponent}
                  id="bp-chart"
                  latest={latest_map}
                  readings={@bp_readings}
                  devices={@devices}
                />
              <% :dialysis -> %>
                <% latest_map = List.first(@dialysis_readings) %>
                <.live_component
                  module={AnkaaWeb.Monitoring.DialysisComponent}
                  id="dialysis-chart"
                  latest={latest_map}
                  readings={@dialysis_readings}
                  devices={@devices}
                />
            <% end %>
          </div>
        </div>
      <% else %>
        <div class="bg-white rounded-3xl p-12 text-center border-2 border-dashed border-slate-200 hover:border-purple-200 transition-colors group animate-fade-in-up">
          <div class="w-24 h-24 bg-purple-50 text-purple-600 rounded-full flex items-center justify-center mx-auto mb-6 group-hover:scale-110 transition-transform duration-300">
            <.icon name="hero-play" class="w-12 h-12 ml-1" />
          </div>
          <h3 class="text-2xl font-bold text-slate-900 mb-2">Ready to start?</h3>
          <p class="text-slate-500 mb-8 max-w-md mx-auto">
            Ensure your blood pressure cuff and dialysis machine are connected. Starting a session will notify your care team.
          </p>
          <button
            phx-click="start_session"
            phx-target={@myself}
            class="bg-purple-600 hover:bg-purple-700 text-white px-10 py-5 rounded-2xl font-bold text-lg shadow-xl shadow-purple-200 transition transform hover:-translate-y-1"
          >
            Start Dialysis Session
          </button>
        </div>
      <% end %>
    </div>
    """
  end

  # Helper to map simulation types
  defp map_device_type("blood_pressure"), do: "bp"
  defp map_device_type("dialysis"), do: "dialysis"
  defp map_device_type(_), do: "bp"
end
