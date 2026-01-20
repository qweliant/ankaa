defmodule AnkaaWeb.PatientDashboard.Components.HealthComponent do
  @moduledoc """
  A component that provides a "Health & Wellness" view for patients, showing key treatment information
  and a daily mood tracker.
  """
  use AnkaaWeb, :live_component
  alias Ankaa.Patients

  @impl true
  def update(assigns, socket) do
    todays_mood_entry = Patients.get_mood_entry_for_today(assigns.patient.id)

    mood_form =
      if todays_mood_entry,
        do: Patients.get_mood_tracker_changeset(todays_mood_entry),
        else: Patients.create_mood_tracker_changeset(assigns.patient)

    treatment_plan = Patients.get_treatment_plan(assigns.patient.id)

    # UPDATED: Dummy data structure to match your specific layout requirements
    dummy_data = %{
      monthly_stats: %{
        treatments_completed: 12,
        average_uf_removed: "2.3 L",
        average_session_duration: "3.8 hours",
        kt_v_ratio: "1.4",
        urea_reduction_ratio: "70%"
      },
      treatment_history: [
        %{
          date: "Apr 15, 2024",
          duration: "3.9 hours",
          uf_removed: "2.4 L",
          access_type: "AV Fistula",
          complications: "None",
          notes: "Treatment completed successfully."
        },
        %{
          date: "Apr 13, 2024",
          duration: "4.0 hours",
          uf_removed: "2.5 L",
          access_type: "AV Fistula",
          complications: "Low BP",
          notes: "Required saline bolus during last hour."
        },
        %{
          date: "Apr 10, 2024",
          duration: "3.8 hours",
          uf_removed: "2.3 L",
          access_type: "AV Fistula",
          complications: "None",
          notes: "Routine treatment."
        }
      ]
    }

    {:ok,
     assign(
       socket,
       assigns
       |> Map.merge(%{
         todays_mood_entry: todays_mood_entry,
         mood_form: mood_form,
         treatment_plan: treatment_plan,
         data: dummy_data
       })
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto space-y-8 animate-fade-in-up">
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-2xl font-bold text-slate-800">Health & Wellness</h2>
          <p class="text-sm text-slate-500">Track your progress and daily condition</p>
        </div>
      </div>

      <div class="bg-white shadow rounded-4xl overflow-hidden border border-slate-100">
        <div class="px-6 py-5 border-b border-slate-100 bg-slate-50/50">
          <h3 class="text-lg leading-6 font-medium text-gray-900">My Session Information</h3>
          <p class="mt-1 max-w-2xl text-sm text-gray-500">Prescribed treatment targets</p>
        </div>

        <div class="px-6 py-6">
          <dl class="grid grid-cols-1 gap-x-4 gap-y-8 sm:grid-cols-2 lg:grid-cols-5">
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Dialysis Schedule</dt>
              <dd class="mt-1 text-lg font-semibold text-purple-700">
                {if @treatment_plan, do: @treatment_plan.frequency, else: "--"}
              </dd>
            </div>
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Duration</dt>
              <dd class="mt-1 text-lg font-semibold text-gray-900">
                <%= if @treatment_plan && @treatment_plan.duration_minutes do %>
                  {@treatment_plan.duration_minutes} mins
                <% else %>
                  --
                <% end %>
              </dd>
            </div>
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Access Type</dt>
              <dd class="mt-1 text-lg font-semibold text-gray-900">
                {if @treatment_plan, do: @treatment_plan.access_type, else: "--"}
              </dd>
            </div>
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Dry Weight</dt>
              <dd class="mt-1 text-lg font-semibold text-gray-900">
                <%= if @treatment_plan && @treatment_plan.dry_weight do %>
                  {@treatment_plan.dry_weight} kg
                <% else %>
                  --
                <% end %>
              </dd>
            </div>
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Target UF</dt>
              <dd class="mt-1 text-lg font-semibold text-gray-900">
                <%= if @treatment_plan && @treatment_plan.target_ultrafiltration do %>
                  {@treatment_plan.target_ultrafiltration} L
                <% else %>
                  --
                <% end %>
              </dd>
            </div>
          </dl>
        </div>
      </div>

      <div class="bg-white rounded-4xl p-1 border border-slate-100 shadow-sm">
        <.live_component
          module={AnkaaWeb.DailyTrackerComponent}
          id="health-mood-tracker"
          current_user={@current_user}
          entry={@todays_mood_entry}
          form={@mood_form}
        />
      </div>

      <div class="bg-white shadow rounded-4xl overflow-hidden border border-slate-100">
        <div class="px-6 py-5 border-b border-slate-100">
          <h3 class="text-lg leading-6 font-medium text-gray-900">Monthly Statistics</h3>
          <p class="mt-1 max-w-2xl text-sm text-gray-500">Treatment performance overview</p>
        </div>
        <div class="px-6 py-6">
          <dl class="grid grid-cols-1 gap-x-4 gap-y-8 sm:grid-cols-2 lg:grid-cols-4">
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Treatments Completed</dt>
              <dd class="mt-1 text-2xl font-semibold text-gray-900">
                {@data.monthly_stats.treatments_completed}
              </dd>
            </div>
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Average UF Removed</dt>
              <dd class="mt-1 text-2xl font-semibold text-gray-900">
                {@data.monthly_stats.average_uf_removed}
              </dd>
            </div>
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Avg Session Duration</dt>
              <dd class="mt-1 text-2xl font-semibold text-gray-900">
                {@data.monthly_stats.average_session_duration}
              </dd>
            </div>
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Kt/V Ratio</dt>
              <dd class="mt-1 text-2xl font-semibold text-gray-900">
                {@data.monthly_stats.kt_v_ratio}
              </dd>
            </div>
          </dl>
        </div>
      </div>

      <div class="bg-white shadow overflow-hidden sm:rounded-4xl border border-slate-100">
        <div class="px-4 py-5 sm:px-6 border-b border-gray-200">
          <h3 class="text-lg leading-6 font-medium text-gray-900">Treatment History</h3>
          <p class="mt-1 max-w-2xl text-sm text-gray-500">Recent dialysis sessions</p>
        </div>
        <div>
          <ul role="list" class="divide-y divide-gray-200">
            <%= for treatment <- @data.treatment_history do %>
              <li class="px-4 py-4 sm:px-6 hover:bg-slate-50 transition-colors">
                <div class="flex items-center justify-between">
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-medium text-gray-900 truncate">
                      {treatment.date}
                    </p>
                    <div class="mt-2 grid grid-cols-2 gap-4">
                      <div>
                        <p class="text-sm text-gray-500">Duration: {treatment.duration}</p>
                        <p class="text-sm text-gray-500">UF Removed: {treatment.uf_removed}</p>
                      </div>
                      <div>
                        <p class="text-sm text-gray-500">Access: {treatment.access_type}</p>
                        <p class="text-sm text-gray-500">Complications: {treatment.complications}</p>
                      </div>
                    </div>
                    <p class="mt-2 text-sm text-gray-500 italic">Note: {treatment.notes}</p>
                  </div>
                </div>
              </li>
            <% end %>
          </ul>
        </div>
      </div>
    </div>
    """
  end
end
