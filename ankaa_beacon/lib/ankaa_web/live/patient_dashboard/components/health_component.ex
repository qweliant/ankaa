defmodule AnkaaWeb.PatientDashboard.Components.HealthComponent do
  use AnkaaWeb, :live_component
  alias Ankaa.Patients
  alias Ankaa.Sessions

  @impl true
  def update(assigns, socket) do
    todays_entry = Patients.get_mood_entry_for_today(assigns.patient.id)
    treatment_plan = Patients.get_treatment_plan(assigns.patient.id)

    # 1. FETCH REAL SESSIONS
    real_sessions = Sessions.list_sessions_for_patient(assigns.patient.id, limit: 5)

    # 2. ENRICH THEM (Mix Real DB data with Dummy UI data)
    display_sessions = Enum.map(real_sessions, &enrich_session/1)

    # 3. CALCULATE METRICS ON THE DISPLAY DATA
    avg_uf = calculate_avg_uf(display_sessions)
    safety_streak = calculate_safety_streak(display_sessions)

    {:ok,
     assign(socket,
       patient: assigns.patient,
       current_user: assigns.current_user,
       todays_entry: todays_entry,
       treatment_plan: treatment_plan,
       recent_sessions: display_sessions, # <--- We use the enriched list
       avg_uf: avg_uf,
       safety_streak: safety_streak,
       selected_symptom: nil
     )}
  end

  @impl true
  def handle_event("log_status", %{"status" => status}, socket) do
    {:noreply, assign(socket, selected_symptom: status)}
  end

  # --- THE "FLO" UI TEMPLATE ---
  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto space-y-8 animate-fade-in-up">
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-2xl font-bold text-slate-800">Health & Safety Trends</h2>
          <p class="text-sm text-slate-500">Monitoring your body's response to treatment</p>
        </div>
      </div>

      <div class="bg-white rounded-4xl p-8 border border-slate-100 shadow-sm relative overflow-hidden">
        <%= if @todays_entry && is_nil(@selected_symptom) do %>
          <div class="text-center py-6">
            <div class="inline-flex items-center justify-center w-20 h-20 bg-green-50 text-green-600 rounded-full mb-4">
              <.icon name="hero-check-circle" class="w-10 h-10" />
            </div>
            <h3 class="text-2xl font-black text-slate-800 mb-2">Check-in Complete</h3>
            <p class="text-slate-500">You logged <strong>{@todays_entry.mood}</strong> today.</p>
          </div>
        <% else %>
          <h3 class="text-xl font-bold text-slate-800 mb-6 flex items-center gap-2">
            <.icon name="hero-heart" class="w-6 h-6 text-rose-500" />
            How does your body feel right now?
          </h3>

          <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            <.status_btn icon="hero-face-smile" label="Ready / Good" value="Great" color="peer-checked:bg-emerald-500 peer-checked:text-white" base="emerald" target={@myself} />
            <.status_btn icon="hero-battery-50" label="Washed Out" value="Tired" color="peer-checked:bg-slate-600 peer-checked:text-white" base="slate" target={@myself} />
            <.status_btn icon="hero-bolt" label="Cramping" value="Cramping" color="peer-checked:bg-amber-500 peer-checked:text-white" base="amber" target={@myself} />
            <.status_btn icon="hero-exclamation-triangle" label="Dizzy / Nauseous" value="Dizzy" color="peer-checked:bg-rose-500 peer-checked:text-white" base="rose" target={@myself} />
          </div>

          <%= if @selected_symptom do %>
             <div class="mt-8 bg-slate-50 rounded-2xl p-6 border-l-4 border-purple-500 animate-fade-in">
              <h4 class="font-bold text-slate-900 mb-1 flex items-center gap-2">
                <.icon name="hero-sparkles" class="w-5 h-5 text-purple-600" />
                Safety Insight
              </h4>
              <p class="text-slate-700 text-sm leading-relaxed">
                {safety_message(@selected_symptom)}
              </p>
            </div>
          <% end %>
        <% end %>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div class="bg-white p-6 rounded-4xl border border-slate-100 shadow-sm flex flex-col justify-between h-48 relative overflow-hidden">
          <div class="relative z-10">
            <div class="flex items-start justify-between mb-2">
               <dt class="text-xs font-bold uppercase tracking-wider text-slate-400">Fluid Burden (Avg)</dt>
               <.icon name="hero-beaker" class="w-5 h-5 text-blue-400" />
            </div>
            <dd class="text-4xl font-black text-slate-800">
              {@avg_uf} <span class="text-lg font-medium text-slate-400">L</span>
            </dd>
            <%= if @avg_uf > 2.5 do %>
              <p class="text-xs text-rose-600 font-bold bg-rose-50 px-2 py-1 rounded-md inline-block mt-2">
                 High Removal Rates
              </p>
              <p class="mt-3 text-xs text-slate-500">
                You are removing a lot of fluid. This increases cramping risk.
              </p>
            <% else %>
               <p class="text-xs text-emerald-600 font-bold bg-emerald-50 px-2 py-1 rounded-md inline-block mt-2">
                 Stable Range
              </p>
              <p class="mt-3 text-xs text-slate-500">
                You are keeping your fluid gains low. Treatments are safer.
              </p>
            <% end %>
          </div>
        </div>

        <div class="bg-linear-to-br from-indigo-900 to-slate-800 p-6 rounded-4xl shadow-lg text-white relative overflow-hidden flex flex-col justify-between h-48">
          <div class="relative z-10">
            <div class="flex items-start justify-between mb-2">
               <dt class="text-xs font-bold uppercase tracking-wider text-indigo-200">Safety Streak</dt>
               <.icon name="hero-shield-check" class="w-5 h-5 text-indigo-300" />
            </div>
            <dd class="text-4xl font-black text-white">
              {@safety_streak} <span class="text-lg font-medium text-indigo-200">Sessions</span>
            </dd>
            <p class="mt-2 text-sm text-indigo-100 font-medium">Without Critical Alerts</p>
          </div>
          <div class="absolute top-0 right-0 -mt-4 -mr-4 w-24 h-24 bg-indigo-500 rounded-full blur-3xl opacity-20"></div>
        </div>
      </div>

      <div class="bg-white shadow rounded-4xl overflow-hidden border border-slate-100">
        <div class="px-6 py-5 border-b border-slate-100 flex justify-between items-center">
          <h3 class="text-lg font-bold text-gray-900">Recent Session Log</h3>
        </div>

        <div class="divide-y divide-gray-100">
          <%= for session <- @recent_sessions do %>
            <div class="p-6 hover:bg-slate-50 transition flex items-center justify-between group">
              <div>
                <p class="font-bold text-slate-800 text-lg">
                  <%= Calendar.strftime(session.start_time, "%b %d, %Y") %>
                </p>
                <div class="flex items-center gap-3 mt-1">
                   <p class="text-xs font-bold text-slate-500 bg-slate-100 px-2 py-0.5 rounded">
                     {session.duration_str}
                   </p>
                   <p class="text-xs text-slate-400">
                     Removed {session.uf_removed_str} L
                   </p>
                </div>
              </div>

              <div class="flex items-center gap-4">
                <%= if session.has_critical_alerts do %>
                   <span class="flex items-center gap-1 bg-rose-50 text-rose-600 text-xs px-3 py-1.5 rounded-full font-bold">
                     <.icon name="hero-exclamation-circle" class="w-4 h-4" />
                     Alerts
                   </span>
                <% else %>
                   <span class="flex items-center gap-1 bg-emerald-50 text-emerald-600 text-xs px-3 py-1.5 rounded-full font-bold">
                     <.icon name="hero-check-circle" class="w-4 h-4" />
                     Smooth
                   </span>
                <% end %>

                <.icon name="hero-chevron-right" class="w-5 h-5 text-slate-300 group-hover:text-purple-600 transition" />
              </div>
            </div>
          <% end %>

          <%= if Enum.empty?(@recent_sessions) do %>
            <div class="p-8 text-center text-slate-400">
              <p>No sessions recorded yet.</p>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # --- DUMMY DATA GENERATOR ---

  # Takes a real DB struct and adds fake UI fields
  defp enrich_session(session) do
    # 1. Calculate Duration from real times, or fake it
    duration_mins =
      if session.end_time do
        DateTime.diff(session.end_time, session.start_time, :minute)
      else
        # If ongoing, assume it started 2 hours ago for display
        120
      end

    # 2. Convert mins to pretty string "3h 45m"
    hours = div(duration_mins, 60)
    mins = rem(duration_mins, 60)
    duration_str = "#{hours}h #{mins}m"

    # 3. Create deterministic dummy data based on ID (so it doesn't change on refresh)
    # We use the byte size of the ID to seed a pseudo-random choice
    seed = byte_size(session.id || "default")

    # Fake UF Removal: Between 2.0 and 3.0 Liters
    # We add a tiny bit of randomness based on the second of the start_time
    uf_removed = 2.0 + (session.start_time.second / 60.0)
    uf_removed_str = :erlang.float_to_binary(uf_removed, [decimals: 2])

    # Fake Alerts: 10% chance of critical alert
    has_critical_alerts = rem(session.start_time.second, 10) == 0

    %{
      id: session.id,
      start_time: session.start_time,
      status: session.status,
      # New Dummy Fields
      duration_str: duration_str,
      uf_removed: uf_removed,
      uf_removed_str: uf_removed_str,
      has_critical_alerts: has_critical_alerts
    }
  end

  # --- METRIC CALCULATORS ---

  defp calculate_avg_uf(sessions) do
    case sessions do
      [] -> 0.0
      list ->
        total = Enum.reduce(list, 0.0, fn s, acc -> acc + s.uf_removed end)
        Float.round(total / length(list), 2)
    end
  end

  defp calculate_safety_streak(sessions) do
    # Count how many sessions in a row (from top down) have NO alerts
    Enum.reduce_while(sessions, 0, fn session, count ->
      if !session.has_critical_alerts do
        {:cont, count + 1}
      else
        {:halt, count}
      end
    end)
  end

  # --- UI HELPERS (Keep these exactly as before) ---

  defp status_btn(assigns) do
    ~H"""
    <button phx-click="log_status" phx-value-status={@value} phx-target={@target}
      class={"group relative flex flex-col items-center justify-center p-4 rounded-3xl border-2 transition-all hover:scale-[1.02] " <>
        border_color(@base) <> " " <> bg_hover(@base)
    }>
       <div class={"w-12 h-12 rounded-full flex items-center justify-center mb-3 transition-colors " <> icon_bg(@base)}>
          <.icon name={@icon} class={"w-6 h-6 " <> icon_color(@base)} />
       </div>
       <span class="text-xs font-bold text-slate-600 group-hover:text-slate-900">{@label}</span>
    </button>
    """
  end

  defp border_color("emerald"), do: "border-emerald-100"
  defp border_color("slate"), do: "border-slate-100"
  defp border_color("amber"), do: "border-amber-100"
  defp border_color("rose"), do: "border-rose-100"

  defp bg_hover("emerald"), do: "hover:bg-emerald-50 hover:border-emerald-200"
  defp bg_hover("slate"), do: "hover:bg-slate-50 hover:border-slate-200"
  defp bg_hover("amber"), do: "hover:bg-amber-50 hover:border-amber-200"
  defp bg_hover("rose"), do: "hover:bg-rose-50 hover:border-rose-200"

  defp icon_bg("emerald"), do: "bg-emerald-100 group-hover:bg-emerald-200"
  defp icon_bg("slate"), do: "bg-slate-100 group-hover:bg-slate-200"
  defp icon_bg("amber"), do: "bg-amber-100 group-hover:bg-amber-200"
  defp icon_bg("rose"), do: "bg-rose-100 group-hover:bg-rose-200"

  defp icon_color("emerald"), do: "text-emerald-600"
  defp icon_color("slate"), do: "text-slate-600"
  defp icon_color("amber"), do: "text-amber-600"
  defp icon_color("rose"), do: "text-rose-600"

  defp safety_message("Great"), do: "You are feeling ready! This is a great baseline. Keep doing exactly what you are doing."
  defp safety_message("Tired"), do: "Post-dialysis washout? You might have removed too much fluid on average. Rest and rehydrate slowly."
  defp safety_message("Cramping"), do: "Cramping often means fluid is being pulled too fast. Consider lowering your UF Rate next time."
  defp safety_message("Dizzy"), do: "⚠️ SAFETY ALERT: Dizziness is a sign of hypotension (Low BP). Do not stand up quickly."
end
