defmodule AnkaaWeb.PatientDashboard.Components.FamilyPeaceComponent do
  @moduledoc """
  A component that provides a "Family Peace" view for caregivers, showing a high-level status
  of the patient's well-being, recent session history, and quick access to communication tools.
  """
  use AnkaaWeb, :live_component

  alias Ankaa.Patients
  alias Ankaa.Sessions
  alias AnkaaWeb.FridgeCardComponent
  alias AnkaaWeb.Monitoring.BPComponent
  alias AnkaaWeb.Monitoring.DialysisComponent

  @impl true
  def update(%{patient: patient, current_user: current_user} = assigns, socket) do
    relationship = Patients.get_relationship(current_user, patient)
    care_network_entry = Patients.get_care_network_entry(current_user.id, patient.id)
    latest_session = Sessions.get_latest_session_for_patient(patient)
    recent_sessions = Sessions.list_sessions_for_patient(patient.id)

    {status, last_check} =
      case latest_session do
        %Sessions.Session{status: s, start_time: st} -> {String.capitalize(s), st}
        nil -> {"No Sessions", nil}
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       relationship: relationship,
       care_network_entry: care_network_entry,
       status: status,
       last_check: last_check,
       recent_sessions: recent_sessions,
       show_chat: false
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto space-y-8 pb-12">
      <div class="flex items-center justify-between px-2">
        <div>
          <h2 class="text-3xl font-bold text-stone-800 tracking-tight">
            {greeting(@current_user)}, {@current_user.first_name}
          </h2>
          <p class="text-stone-500 mt-1">
            Here is the latest update for <strong>{@patient.name}</strong>.
          </p>
          <div class="mt-6">
            <.live_component
              module={AnkaaWeb.CheckInButton}
              id={"check-in-btn-for-#{@patient.id}"}
              patient={@patient}
              current_user={@current_user}
            />
          </div>
        </div>
        <button class="p-3 bg-white rounded-2xl shadow-sm text-stone-400 hover:text-stone-600 transition">
          <.icon name="hero-bell" class="w-6 h-6" />
        </button>
      </div>

      <div class="relative overflow-hidden rounded-[2.5rem] bg-linear-to-br from-[#FFFBF7] to-[#F5F2EE] p-8 sm:p-12 text-center shadow-[0_20px_40px_-15px_rgba(0,0,0,0.05)] border border-white">
        <div
          class="absolute top-0 left-0 w-full h-full opacity-50 pointer-events-none"
          style="background-image: radial-gradient(#E7E5E4 1px, transparent 1px); background-size: 24px 24px;"
        >
        </div>

        <div class="relative z-10 flex flex-col items-center">
          <div class={[
            "w-64 h-64 rounded-full flex items-center justify-center shadow-[inset_0_4px_20px_rgba(0,0,0,0.05)] mb-8 transition-all duration-700",
            status_circle_bg(@status)
          ]}>
            <div class={[
              "w-48 h-48 rounded-full flex flex-col items-center justify-center shadow-lg transform transition-transform duration-500",
              status_inner_circle_bg(@status)
            ]}>
              <.icon name={status_icon(@status)} class="w-12 h-12 text-white mb-2" />
              <span class="text-white font-medium text-lg tracking-wide">
                {@patient.name} is {status_text(@status)}
              </span>
            </div>
          </div>

          <div class="space-y-1">
            <p class="text-stone-500 font-medium uppercase tracking-widest text-xs">Last Update</p>
            <p class="text-stone-800 text-xl font-semibold">
              {if @last_check, do: Calendar.strftime(@last_check, "%-I:%M %p"), else: "Just now"}
            </p>
            <p class="text-stone-400 text-sm">
              {if @status == "Ongoing", do: "Session in progress", else: "Session #{@status}"}
            </p>
          </div>
        </div>
      </div>
      <%!-- <%= if @has_vitals_permission and @status == "Ongoing" do %>
        <div class="bg-white/80 backdrop-blur-sm rounded-3xl p-6 border border-stone-100 shadow-sm">
          <div class="flex items-center gap-3 mb-6">
            <span class="relative flex h-3 w-3">
              <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75">
              </span>
              <span class="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
            </span>
            <h3 class="text-stone-700 font-semibold">Live Monitor</h3>
          </div>

          <div class="space-y-8">
            <.live_component
              module={BPComponent}
              id="caregiver-bp-monitor"
              devices={@devices}
              readings={@bp_readings}
            />
            <hr class="border-stone-100" />
            <.live_component
              module={DialysisComponent}
              id="caregiver-dialysis-monitor"
              devices={@devices}
              readings={@dialysis_readings}
            />
          </div>
        </div>
      <% end %> --%>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div class="bg-white rounded-3xl p-6 shadow-sm border border-stone-100">
          <h3 class="text-stone-700 font-semibold mb-4">Quick Connect</h3>
          <.live_component
            module={FridgeCardComponent}
            id={"fridge-card-for-#{@patient.id}"}
            care_network_entry={@care_network_entry}
            patient={@patient}
            current_user={@current_user}
          />
        </div>

        <div class="bg-white rounded-3xl p-6 shadow-sm border border-stone-100">
          <h3 class="text-stone-700 font-semibold mb-4">Recent Days</h3>
          <div class="space-y-4">
            <%= for session <- Enum.take(@recent_sessions, 3) do %>
              <div class="flex items-center justify-between p-3 rounded-2xl bg-stone-50">
                <div class="flex items-center gap-3">
                  <div class={[
                    "w-2 h-10 rounded-full",
                    status_bar_color(session.status)
                  ]}>
                  </div>
                  <div>
                    <p class="text-stone-900 font-medium">
                      {Calendar.strftime(session.start_time, "%a, %b %d")}
                    </p>
                    <p class="text-xs text-stone-500">
                      {Calendar.strftime(session.start_time, "%-I:%M %p")}
                    </p>
                  </div>
                </div>
                <span class={[
                  "px-3 py-1 rounded-full text-xs font-semibold",
                  status_pill_color(session.status)
                ]}>
                  {String.capitalize(session.status)}
                </span>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp greeting(user) do
    timezone = Map.get(user, :timezone, "Etc/UTC") || "Etc/UTC"
    now = DateTime.utc_now() |> DateTime.shift_zone!(timezone)

    cond do
      now.hour < 12 -> "Good Morning"
      now.hour < 18 -> "Good Afternoon"
      true -> "Good Evening"
    end
  end

  defp status_circle_bg(status) do
    case String.capitalize(status) do
      "Ongoing" -> "bg-blue-50"
      "Completed" -> "bg-[#E8F5E9]"
      "Aborted" -> "bg-red-50"
      _ -> "bg-stone-100"
    end
  end

  defp status_inner_circle_bg(status) do
    case String.capitalize(status) do
      "Ongoing" -> "bg-blue-400 shadow-blue-200"
      "Completed" -> "bg-[#66BB6A] shadow-green-200"
      "Aborted" -> "bg-red-400 shadow-red-200"
      _ -> "bg-stone-400 shadow-stone-200"
    end
  end

  defp status_icon(status) do
    case String.capitalize(status) do
      "Ongoing" -> "hero-arrow-path"
      "Completed" -> "hero-check"
      "Aborted" -> "hero-exclamation-triangle"
      _ -> "hero-moon"
    end
  end

  defp status_text(status) do
    case String.capitalize(status) do
      "Ongoing" -> "in Treatment"
      "Completed" -> "Stable"
      "Aborted" -> "Needs Help"
      _ -> "Resting"
    end
  end

  defp status_bar_color(status) do
    case String.capitalize(status) do
      "Ongoing" -> "bg-blue-400"
      "Completed" -> "bg-green-400"
      "Aborted" -> "bg-red-400"
      _ -> "bg-stone-300"
    end
  end

  defp status_pill_color(status) do
    case String.capitalize(status) do
      "Ongoing" -> "bg-blue-100 text-blue-700"
      "Completed" -> "bg-green-100 text-green-700"
      "Aborted" -> "bg-red-100 text-red-700"
      _ -> "bg-stone-200 text-stone-600"
    end
  end
end
