defmodule AnkaaWeb.HealthLive do
  use AnkaaWeb, :live_view
  use AnkaaWeb, :patient_layout

  @impl true
  def mount(_params, _session, socket) do
    dummy_data = %{
      patient_info: %{
        name: "John Doe",
        dialysis_schedule: "MWF 8:00 AM - 12:00 PM",
        treatment_duration: "4 hours",
        access_type: "AV Fistula",
        dry_weight: "75 kg",
        target_uf: "2.5 L"
      },
      monthly_stats: %{
        treatments_completed: 12,
        average_uf_removed: "2.3 L",
        average_session_duration: "3.8 hours",
        blood_pressure_trend: "stable",
        weight_trend: "stable",
        kt_v_ratio: "1.4",
        urea_reduction_ratio: "70%"
      },
      historical_trends: [
        %{
          date: ~D[2024-04-01],
          uf_removed: "2.4 L",
          session_duration: "3.9 hours",
          pre_bp: "130/80",
          post_bp: "125/75",
          kt_v: "1.4"
        },
        %{
          date: ~D[2024-03-25],
          uf_removed: "2.3 L",
          session_duration: "3.8 hours",
          pre_bp: "135/85",
          post_bp: "130/80",
          kt_v: "1.3"
        },
        %{
          date: ~D[2024-03-18],
          uf_removed: "2.5 L",
          session_duration: "4.0 hours",
          pre_bp: "140/90",
          post_bp: "135/85",
          kt_v: "1.5"
        }
      ],
      treatment_history: [
        %{
          date: ~D[2024-04-15],
          duration: "3.9 hours",
          uf_removed: "2.4 L",
          access_type: "AV Fistula",
          complications: "None",
          notes: "Treatment completed successfully"
        },
        %{
          date: ~D[2024-04-13],
          duration: "4.0 hours",
          uf_removed: "2.5 L",
          access_type: "AV Fistula",
          complications: "Low blood pressure",
          notes: "Required saline bolus"
        },
        %{
          date: ~D[2024-04-10],
          duration: "3.8 hours",
          uf_removed: "2.3 L",
          access_type: "AV Fistula",
          complications: "None",
          notes: "Routine treatment"
        }
      ]
    }

    {:ok,
     assign(socket,
       data: dummy_data,
       current_path: "/patient/health"
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- Patient Information -->
      <div class="bg-white shadow overflow-hidden sm:rounded-lg mb-8">
        <div class="px-4 py-5 sm:px-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900">Patient Information</h3>
          <p class="mt-1 max-w-2xl text-sm text-gray-500">Treatment schedule and targets</p>
        </div>
        <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
          <dl class="grid grid-cols-1 gap-x-4 gap-y-8 sm:grid-cols-2">
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Dialysis Schedule</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @data.patient_info.dialysis_schedule %></dd>
            </div>
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Treatment Duration</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @data.patient_info.treatment_duration %></dd>
            </div>
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Access Type</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @data.patient_info.access_type %></dd>
            </div>
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Dry Weight</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @data.patient_info.dry_weight %></dd>
            </div>
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Target UF</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @data.patient_info.target_uf %></dd>
            </div>
          </dl>
        </div>
      </div>

      <!-- Monthly Statistics -->
      <div class="bg-white shadow overflow-hidden sm:rounded-lg mb-8">
        <div class="px-4 py-5 sm:px-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900">Monthly Statistics</h3>
          <p class="mt-1 max-w-2xl text-sm text-gray-500">Treatment performance overview</p>
        </div>
        <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
          <dl class="grid grid-cols-1 gap-x-4 gap-y-8 sm:grid-cols-2">
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Treatments Completed</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @data.monthly_stats.treatments_completed %></dd>
            </div>
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Average UF Removed</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @data.monthly_stats.average_uf_removed %></dd>
            </div>
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Average Session Duration</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @data.monthly_stats.average_session_duration %></dd>
            </div>
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Kt/V Ratio</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @data.monthly_stats.kt_v_ratio %></dd>
            </div>
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Urea Reduction Ratio</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @data.monthly_stats.urea_reduction_ratio %></dd>
            </div>
          </dl>
        </div>
      </div>

      <!-- Treatment History -->
      <div class="bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900">Treatment History</h3>
          <p class="mt-1 max-w-2xl text-sm text-gray-500">Recent dialysis sessions</p>
        </div>
        <div class="border-t border-gray-200">
          <ul role="list" class="divide-y divide-gray-200">
            <%= for treatment <- @data.treatment_history do %>
              <li class="px-4 py-4 sm:px-6">
                <div class="flex items-center justify-between">
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-medium text-gray-900 truncate">
                      <%= treatment.date %>
                    </p>
                    <div class="mt-2 grid grid-cols-2 gap-4">
                      <div>
                        <p class="text-sm text-gray-500">Duration: <%= treatment.duration %></p>
                        <p class="text-sm text-gray-500">UF Removed: <%= treatment.uf_removed %></p>
                      </div>
                      <div>
                        <p class="text-sm text-gray-500">Access: <%= treatment.access_type %></p>
                        <p class="text-sm text-gray-500">Complications: <%= treatment.complications %></p>
                      </div>
                    </div>
                    <p class="mt-2 text-sm text-gray-500"><%= treatment.notes %></p>
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
