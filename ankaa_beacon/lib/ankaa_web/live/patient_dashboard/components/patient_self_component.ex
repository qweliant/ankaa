defmodule AnkaaWeb.PatientDashboard.Components.PatientSelfComponent do
  @moduledoc """
  The Patient "Hub". This component handles the main dashboard view and
  switches between sub-components (Monitoring, Health, Devices) internally.
  """
  use AnkaaWeb, :live_component

  alias Ankaa.Patients
  alias Ankaa.Sessions

  alias AnkaaWeb.PatientDashboard.Components.MonitoringComponent
  alias AnkaaWeb.PatientDashboard.Components.HealthComponent
  alias AnkaaWeb.PatientDashboard.Components.DevicesComponent
  alias AnkaaWeb.PatientDashboard.Components.CareNetworkComponent

  @impl true
  def update(assigns, socket) do
    socket =
      if Map.has_key?(socket.assigns, :latest_session) do
        socket
      else
        patient_id = assigns.patient.id

        assign(socket,
          latest_session: Sessions.get_latest_session_for_patient(assigns.patient),
          treatment_plan: Patients.get_treatment_plan(patient_id),
          todays_mood_entry: Patients.get_mood_entry_for_today(patient_id),
          care_team: Patients.list_care_team(patient_id)
        )
      end

    latest_session = Sessions.get_latest_session_for_patient(assigns.patient)
    treatment_plan = Patients.get_treatment_plan(assigns.patient.id)
    todays_mood_entry = Patients.get_mood_entry_for_today(assigns.patient.id)

    status =
      case latest_session do
        %Sessions.Session{status: "ongoing"} -> "Ongoing"
        _ -> "Idle"
      end

    stats = %{
      weekly_streak: 2,
      weekly_goal: 3,
      fluid_intake_today: 0.8,
      fluid_limit: 1.5,
      dry_weight_diff: 1.2
    }

    prepare_readings = fn readings ->
      Enum.map(readings || [], fn reading ->
        id = "#{reading.device_id}-#{DateTime.to_unix(reading.timestamp, :millisecond)}"

        # Convert struct to map and add the ID key
        reading
        |> Map.from_struct()
        |> Map.put(:id, id)
      end)
    end

    socket =
      socket
      |> assign(assigns)
      # Defaults to :home view on mount
      |> assign_new(:active_view, fn -> :home end)
      |> assign(
        status: status,
        treatment_plan: treatment_plan,
        stats: stats,
        latest_session: latest_session,
        todays_mood_entry: todays_mood_entry
      )
      |> assign(:bp_readings, prepare_readings.(assigns[:bp_readings]))
      |> assign(:dialysis_readings, prepare_readings.(assigns[:dialysis_readings]))

    {:ok, socket}
  end

  @impl true
  def handle_event("switch_view", %{"view" => view_str}, socket) do
    view = String.to_existing_atom(view_str)

    socket =
      if view == :home do
        refresh_home_data(socket)
      else
        socket
      end

    {:noreply, assign(socket, active_view: view)}
  end

  @impl true
  def handle_event("log_fluid", _, socket) do
    {:noreply, put_flash(socket, :info, "Fluid logged! (Simulation)")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full pb-12">
      <%= if @active_view != :home do %>
        <div class="mb-6 animate-fade-in">
          <button
            phx-click="switch_view"
            phx-value-view="home"
            phx-target={@myself}
            class="flex items-center text-sm font-bold text-slate-500 hover:text-indigo-600 transition-colors group"
          >
            <div class="w-8 h-8 rounded-full bg-white border border-slate-200 shadow-sm flex items-center justify-center mr-2 group-hover:border-indigo-300">
              <.icon name="hero-arrow-left" class="w-4 h-4" />
            </div>
            Back to Dashboard
          </button>
        </div>
      <% end %>

      <div class="animate-fade-in-up">
        <%= case @active_view do %>
          <% :home -> %>
            <div class="max-w-4xl mx-auto space-y-8">
              <div class="bg-white rounded-4xl shadow-xl shadow-purple-100 overflow-hidden border border-purple-50 relative p-8 sm:p-10 text-center">
                <div class="absolute top-0 right-0 -mr-16 -mt-16 w-64 h-64 rounded-full bg-purple-50 opacity-50 blur-3xl pointer-events-none">
                </div>

                <div class="relative z-10">
                  <h2 class="text-3xl sm:text-4xl font-extrabold text-slate-800 tracking-tight mb-2">
                    {greeting(@current_user)}, {@current_user.first_name}
                  </h2>
                  <p class="text-slate-500 text-lg mb-8">
                    Ready for your treatment today?
                  </p>

                  <%= if @status == "Ongoing" do %>
                    <div class="inline-block relative">
                      <span class="absolute top-0 right-0 -mt-2 -mr-2 flex h-6 w-6">
                        <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75">
                        </span>
                        <span class="relative inline-flex rounded-full h-6 w-6 bg-emerald-500 border-2 border-white">
                        </span>
                      </span>
                      <button
                        phx-click="switch_view"
                        phx-value-view="monitoring"
                        phx-target={@myself}
                        class="inline-flex items-center justify-center px-10 py-5 text-xl font-bold text-white transition-all bg-emerald-500 rounded-2xl hover:bg-emerald-600 hover:scale-[1.02] shadow-lg shadow-emerald-200"
                      >
                        <.icon name="hero-play" class="w-8 h-8 mr-3" /> Monitor Session
                      </button>
                    </div>
                    <p class="mt-4 text-sm font-medium text-emerald-700 bg-emerald-50 inline-block px-4 py-1 rounded-full">
                      Session in progress
                    </p>
                  <% else %>
                    <button
                      phx-click="switch_view"
                      phx-value-view="monitoring"
                      phx-target={@myself}
                      class="inline-flex items-center justify-center px-10 py-5 text-xl font-bold text-white transition-all bg-purple-600 rounded-2xl hover:bg-purple-700 hover:scale-[1.02] shadow-lg shadow-purple-200"
                    >
                      <.icon name="hero-bolt" class="w-8 h-8 mr-3" /> Start New Session
                    </button>
                    <%= if @treatment_plan do %>
                      <p class="mt-6 text-sm text-slate-400">
                        Next scheduled: <strong class="text-slate-600">Today</strong>
                        • Duration: {@treatment_plan.duration_minutes}m
                      </p>
                    <% end %>
                  <% end %>
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-6 items-start">
                <div class="space-y-6">
                  <div class="bg-white p-6 rounded-4xl border border-slate-100 shadow-sm relative overflow-hidden group hover:border-purple-200 transition-colors">
                    <div class="flex justify-between items-start mb-4">
                      <div class="bg-purple-50 p-3 rounded-2xl text-purple-600">
                        <.icon name="hero-face-smile" class="w-8 h-8" />
                      </div>
                      <button
                        phx-click="switch_view"
                        phx-value-view="health"
                        phx-target={@myself}
                        class="text-xs font-bold uppercase tracking-wider text-slate-400 hover:text-purple-600 transition-colors"
                      >
                        Full Tracker &rarr;
                      </button>
                    </div>

                    <%= if @todays_mood_entry do %>
                      <h3 class="text-3xl font-black text-slate-800 mb-1">
                        {@todays_mood_entry.mood}
                      </h3>
                      <p class="text-sm font-medium text-slate-500 mb-4">Daily Check-in Complete</p>

                      <div class="w-full bg-slate-100 rounded-full h-3 overflow-hidden">
                        <div class="bg-green-500 h-3 rounded-full w-full"></div>
                      </div>

                      <button
                        phx-click="switch_view"
                        phx-value-view="health"
                        phx-target={@myself}
                        class="mt-6 w-full py-2 rounded-xl border-2 border-dashed border-green-200 text-green-600 font-bold text-sm hover:bg-green-50 transition-colors flex items-center justify-center gap-2"
                      >
                        <.icon name="hero-check" class="w-4 h-4" /> Entry Saved
                      </button>
                    <% else %>
                      <h3 class="text-3xl font-black text-slate-800 mb-1">
                        Hello!
                        <span class="text-lg font-medium text-slate-400 block">
                          How are you feeling?
                        </span>
                      </h3>
                      <p class="text-sm font-medium text-slate-500 mb-4">Daily Check-in Pending</p>

                      <div class="w-full bg-slate-100 rounded-full h-3 overflow-hidden">
                        <div class="bg-purple-500 h-3 rounded-full w-[5%]"></div>
                      </div>

                      <button
                        phx-click="switch_view"
                        phx-value-view="health"
                        phx-target={@myself}
                        class="mt-6 w-full py-2 rounded-xl border-2 border-dashed border-slate-200 text-slate-500 font-bold text-sm hover:border-purple-400 hover:text-purple-600 transition-colors"
                      >
                        + Log Mood
                      </button>
                    <% end %>
                  </div>

                  <div class="bg-slate-50 rounded-4xl p-6 border border-slate-100">
                    <div class="flex justify-between items-center mb-4">
                      <h3 class="text-sm font-bold text-slate-400 uppercase tracking-wider">
                        Your Care Team
                      </h3>
                      <button
                        phx-click="switch_view"
                        phx-value-view="team"
                        phx-target={@myself}
                        class="text-xs font-bold text-purple-600 hover:underline"
                      >
                        View All
                      </button>
                    </div>

                    <div class="flex gap-3 overflow-x-auto pb-2 scrollbar-hide">
                      <%= for member <- Enum.take(@care_team, 3) do %>
                        <button class="shrink-0 flex items-center gap-3 bg-white p-2 pr-4 rounded-2xl shadow-sm border border-slate-100 hover:shadow-md transition">
                          <div class="h-10 w-10 rounded-full bg-purple-100 flex items-center justify-center text-purple-600 font-bold text-xs uppercase">
                            {String.slice(to_string(member.role || "U"), 0, 2)}
                          </div>
                          <div class="text-left">
                            <p class="text-xs font-bold text-slate-800">
                              {member.user.first_name} {String.slice(to_string(member.user.last_name || ""), 0, 1)}.
                            </p>
                            <p class="text-[10px] text-slate-500 capitalize">
                              {to_string(member.user.role || "Provider")}
                            </p>
                          </div>
                        </button>
                      <% end %>

                      <button
                        phx-click="switch_view"
                        phx-value-view="team"
                        phx-target={@myself}
                        class="shrink-0 flex items-center justify-center w-10 h-10 rounded-full bg-slate-200 text-slate-500 hover:bg-slate-300 transition"
                      >
                        <.icon name="hero-plus" class="w-5 h-5" />
                      </button>
                    </div>
                  </div>
                </div>

                <div class="space-y-6">
                  <div class="bg-white p-6 rounded-4xl border border-slate-100 shadow-sm flex items-center justify-between">
                    <div>
                      <p class="text-xs font-bold uppercase tracking-wider text-slate-400 mb-1">
                        Weight Status
                      </p>
                      <h3 class="text-2xl font-black text-slate-800">
                        +{@stats.dry_weight_diff}
                        <span class="text-sm font-medium text-slate-400">kg</span>
                      </h3>
                      <p class="text-xs text-orange-500 font-bold bg-orange-50 px-2 py-0.5 rounded-md inline-block mt-1">
                        Over Dry Weight
                      </p>
                    </div>
                    <div class="h-14 w-14 bg-slate-50 rounded-full flex items-center justify-center text-slate-300">
                      <.icon name="hero-scale" class="w-7 h-7" />
                    </div>
                  </div>

                  <div class="bg-linear-to-br from-purple-600 to-indigo-600 p-6 rounded-4xl shadow-lg text-white relative overflow-hidden flex flex-col justify-between h-48">
                    <div class="relative z-10 flex justify-between items-start">
                      <div>
                        <p class="text-purple-200 text-xs font-bold uppercase tracking-wider mb-1">
                          Weekly Goal
                        </p>
                        <h3 class="text-3xl font-black">
                          {@stats.weekly_streak}
                          <span class="text-lg text-purple-200 font-normal">
                            / {@stats.weekly_goal}
                          </span>
                        </h3>
                      </div>
                      <div class="text-center bg-white/20 p-2 rounded-2xl backdrop-blur-sm">
                        <div class="text-2xl">🔥</div>
                      </div>
                    </div>
                    <div class="relative z-10">
                      <p class="text-sm font-medium text-white/90 mb-3">Treatments Completed</p>
                      <button
                        phx-click="switch_view"
                        phx-value-view="health"
                        phx-target={@myself}
                        class="w-full bg-white/10 hover:bg-white/20 text-white py-2 rounded-xl text-xs font-bold transition border border-white/10"
                      >
                        View Trends
                      </button>
                    </div>
                    <div class="absolute -bottom-4 -right-4 w-24 h-24 bg-white opacity-10 rounded-full blur-xl">
                    </div>
                  </div>

                  <button
                    phx-click="switch_view"
                    phx-value-view="devices"
                    phx-target={@myself}
                    class="w-full bg-white rounded-4xl p-6 border border-slate-100 shadow-sm hover:border-indigo-200 hover:shadow-md transition text-left group flex items-center gap-4"
                  >
                    <div class="h-12 w-12 rounded-full bg-indigo-50 text-indigo-600 flex items-center justify-center group-hover:scale-110 transition-transform shrink-0">
                      <.icon name="hero-cpu-chip" class="w-6 h-6" />
                    </div>
                    <div>
                      <h3 class="text-sm font-bold text-slate-800">My Devices</h3>
                      <p class="text-xs text-slate-500">Configure simulators</p>
                    </div>
                    <div class="ml-auto text-slate-300 group-hover:text-indigo-600 transition-colors">
                      <.icon name="hero-chevron-right" class="w-5 h-5" />
                    </div>
                  </button>
                </div>
              </div>
            </div>
          <% :monitoring -> %>
            <.live_component
              module={MonitoringComponent}
              id="monitoring-sub"
              patient={@patient}
              devices={@devices}
              bp_readings={@bp_readings}
              dialysis_readings={@dialysis_readings}
            />
          <% :health -> %>
            <.live_component
              module={HealthComponent}
              id="health-sub"
              patient={@patient}
              current_user={@current_user}
            />
          <% :devices -> %>
            <.live_component
              module={DevicesComponent}
              id="devices-sub"
              patient={@patient}
              devices={@devices}
            />
          <% :team -> %>
            <.live_component
              module={CareNetworkComponent}
              id="team-sub"
              patient={@patient}
              current_user={@current_user}
            />
        <% end %>
      </div>
    </div>
    """
  end

  defp greeting(user) do
    timezone = Map.get(user, :timezone) || "Etc/UTC"

    now =
      case DateTime.shift_zone(DateTime.utc_now(), timezone) do
        {:ok, dt} -> dt
        _ -> DateTime.utc_now()
      end

    cond do
      now.hour < 12 -> "Good Morning"
      now.hour < 18 -> "Good Afternoon"
      true -> "Good Evening"
    end
  end

  defp refresh_home_data(socket) do
    patient = socket.assigns.patient

    latest_session = Sessions.get_latest_session_for_patient(patient)
    status = if latest_session && latest_session.status == "ongoing", do: "Ongoing", else: "Idle"

    treatment_plan = Patients.get_treatment_plan(patient.id)

    assign(socket,
      latest_session: latest_session,
      status: status,
      treatment_plan: treatment_plan
    )
  end
end
