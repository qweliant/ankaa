defmodule AnkaaWeb.MonitoringLive do
  @moduledoc """
  LiveView dashboard to display real-time BP and dialysis data.
  """
  use AnkaaWeb, :patient_layout
  use AnkaaWeb, :alert_handling

  alias Ankaa.Devices
  alias Ankaa.Alerts
  alias Ankaa.Sessions
  alias Ankaa.MQTT

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Ankaa.PubSub, "bpdevicereading_readings")
      Phoenix.PubSub.subscribe(Ankaa.PubSub, "dialysisdevicereading_readings")
    end

    patient_id = socket.assigns.current_user.patient.id
    devices = Devices.list_devices_for_patient(patient_id)

    active_session =
      Sessions.get_active_session_for_patient(patient_id)

    active_devices_in_session = if active_session, do: devices, else: []

    socket =
      assign(socket,
        active_tab: :blood_pressure,
        bp_violations: [],
        dialysis_violations: [],
        devices: devices,
        current_path: "/patient/monitoring",
        latest_bp: nil,
        latest_dialysis: nil
      )

    socket =
      case active_session do
        nil ->
          assign(socket,
            session_started: false,
            session_start_time: nil,
            active_session: nil,
            active_devices_in_session: []
          )

        session ->
          assign(socket,
            session_started: true,
            session_start_time: session.start_time,
            active_session: session,
            active_devices_in_session: active_devices_in_session
          )
      end

    socket =
      socket
      |> stream(:bp_readings, [])
      |> stream(:dialysis_readings, [])

    {:ok, socket}
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
        devices = Devices.list_devices_for_patient(patient.id)

        command_payload =
          Enum.map(devices, fn device ->
            %{
              device_id: device.id,
              scenario: Macro.underscore(device.simulation_scenario),
              device_type: map_device_type(device.type)
            }
          end)

        MQTT.publish("simulator/control", Jason.encode!(%{start_simulations: command_payload}))

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
           active_session: session,
           active_devices_in_session: devices
         )}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to start session.")}
    end
  end

  @impl true
  def handle_event("end_session", _params, socket) do
    patient_name = socket.assigns.current_user.patient.name || "Your patient"
    patient_id = socket.assigns.current_user.patient.id
    devices = socket.assigns.active_devices_in_session || []
    device_ids = Enum.map(devices, & &1.id)

    stop_payload = %{stop_simulations: device_ids}
    MQTT.publish("simulator/control", Jason.encode!(stop_payload))

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

            {:ok, _alert} =
              Ankaa.Alerts.create_alert(%{
                type: "Session",
                message: alert_message,
                patient_id: patient_id,
                severity: "info"
              })

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
               active_session: nil,
               active_devices_in_session: []
             )}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to end session.")}
        end
    end
  end

  @impl true
  def handle_event("trigger_panic", _params, socket) do
    patient = socket.assigns.current_user.patient

    {:ok, alert} =
      Ankaa.Alerts.create_alert(%{
        patient_id: patient.id,
        type: "manual_panic",
        severity: "critical",
        message: "🚨 PATIENT TRIGGERED MANUAL PANIC BUTTON",
        status: "active"
      })

    case Ankaa.Emergency.trigger_ems(patient, alert) do
      {:ok, dispatch_id} ->
        {:noreply,
         socket
         |> put_flash(:error, "EMERGENCY SERVICES CONTACTED. Dispatch ID: #{dispatch_id}")
         |> push_event("panic_triggered", %{})}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to contact EMS. Call 911 manually!")}
    end
  end

  @impl true
  def handle_info({:new_reading, reading, _opts}, socket) do
    reading_for_stream =
      reading
      |> Map.from_struct()
      |> Map.put(:id, Ecto.UUID.generate())

    socket =
      case reading do
        %Ankaa.Monitoring.BPDeviceReading{} ->
          socket
          |> assign(:latest_bp, reading)
          |> stream_insert(:bp_readings, reading_for_stream, at: 0, limit: 4)

        %Ankaa.Monitoring.DialysisDeviceReading{} ->
          socket
          |> assign(:latest_dialysis, reading)
          |> stream_insert(:dialysis_readings, reading_for_stream, at: 0, limit: 4)

        _ ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="flex items-center justify-between mb-8">
        <div class="fixed bottom-6 left-6 z-50">
          <button
            phx-click="trigger_panic"
            data-confirm="Are you sure? This will contact Emergency Services immediately."
            class="bg-red-600 hover:bg-red-700 text-white font-bold py-4 px-6 rounded-full shadow-xl border-4 border-red-800 flex items-center gap-2"
          >
            <.icon name="hero-exclamation-triangle-solid" class="w-8 h-8" />
            <span>EMERGENCY HELP</span>
          </button>
        </div>
        <h1 class=
        "text-2xl font-bold text-slate-900">Patient Monitoring</h1>
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
            class="mt-4 inline-flex items-center px-6 py-3 border border-transparent text-base font-semibold rounded-md shadow-sm text-white bg-rose-600 hover:bg-rose-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-rose-500 transition"
          >
            End Session
          </button>
        </div>

        <div class="bg-white rounded-lg shadow-sm border border-slate-200 overflow-hidden">
          <div class="border-b border-slate-200">
            <nav class="flex -mb-px">
              <button
                phx-click="switch_tab"
                phx-value-tab="blood_pressure"
                class={"px-4 py-3 text-sm font-medium border-b-2 #{if @active_tab == :blood_pressure, do: "border-indigo-500 text-indigo-600", else: "border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300"}"}
              >
                Blood Pressure
              </button>
              <button
                phx-click="switch_tab"
                phx-value-tab="dialysis"
                class={"px-4 py-3 text-sm font-medium border-b-2 #{if @active_tab == :dialysis, do: "border-indigo-500 text-indigo-600", else: "border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300"}"}
              >
                Dialysis
              </button>
            </nav>
          </div>

          <div class="p-6">
            <%= case @active_tab do %>
              <% :blood_pressure -> %>
                <.live_component
                  module={AnkaaWeb.Monitoring.BPComponent}
                  id="bp-monitor"
                  devices={@devices}
                  latest={@latest_bp}
                  readings={@streams.bp_readings}
                />
              <% :dialysis -> %>
                <.live_component
                  module={AnkaaWeb.Monitoring.DialysisComponent}
                  id="dialysis-monitor"
                  devices={@devices}
                  latest={@latest_dialysis}
                  readings={@streams.dialysis_readings}
                />
            <% end %>
          </div>
        </div>
      <% else %>
        <% # NO SESSION ACTIVE %>
        <div class="bg-white shadow rounded-lg p-6 mb-8 flex flex-col items-center justify-center">
          <h2 class="text-lg font-medium text-gray-900 mb-4">
            Ready to Start Your Dialysis Session?
          </h2>
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
    </div>
    """
  end

  defp map_device_type("blood_pressure"), do: "bp"
  defp map_device_type("dialysis"), do: "dialysis"
  # Default to BP if type is unknown or nil
  defp map_device_type(_), do: "bp"
end
