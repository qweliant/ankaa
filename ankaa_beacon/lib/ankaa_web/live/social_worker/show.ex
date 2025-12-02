defmodule AnkaaWeb.SocialWorker.Show do
  @moduledoc """
  LiveView for displaying detailed social work information for a specific patient.
  """
  use AnkaaWeb, :live_view
  use AnkaaWeb, :alert_handling

  alias Ankaa.Patients

  @impl true
  def mount(%{"id" => patient_id}, _session, socket) do
    patient = Patients.get_patient!(patient_id)
    # Mock data for the detail view
    status = Patients.get_social_status(patient)

    {:ok,
     assign(socket,
       patient: patient,
       status: status,
       active_tab: "barriers"
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-10">
      <nav class="flex mb-8" aria-label="Breadcrumb">
        <ol role="list" class="flex items-center space-x-4">
          <li>
            <div>
              <.link navigate={~p"/case/dashboard"} class="text-gray-400 hover:text-gray-500">
                <.icon name="hero-home" class="h-5 w-5 shrink-0" />
                <span class="sr-only">Home</span>
              </.link>
            </div>
          </li>
          <li>
            <div class="flex items-center">
              <.icon name="hero-chevron-right" class="h-5 w-5 shrink-0 text-gray-400" />
              <span class="ml-4 text-sm font-medium text-gray-500">{@patient.name}</span>
            </div>
          </li>
        </ol>
      </nav>

      <div class="md:flex md:items-center md:justify-between mb-8">
        <div class="min-w-0 flex-1">
          <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:truncate sm:text-3xl sm:tracking-tight">
            {@patient.name}
          </h2>
          <div class="mt-1 flex flex-col sm:mt-0 sm:flex-row sm:flex-wrap sm:space-x-6">
            <div class="mt-2 flex items-center text-sm text-gray-500">
              <.icon name="hero-cake" class="mr-1.5 h-5 w-5 shrink-0 text-gray-400" />
              DOB: {@patient.date_of_birth}
            </div>
            <div class="mt-2 flex items-center text-sm text-gray-500">
              <.icon name="hero-map-pin" class="mr-1.5 h-5 w-5 shrink-0 text-gray-400" />
              Transplant Region 3 (Mock)
            </div>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div class="bg-white shadow sm:rounded-lg">
          <div class="px-4 py-5 sm:px-6 border-b border-gray-200">
            <h3 class="text-base font-semibold leading-6 text-gray-900">
              Barriers to Care Assessment
            </h3>
          </div>
          <div class="px-4 py-5 sm:p-6">
            <dl class="grid grid-cols-1 gap-x-4 gap-y-6 sm:grid-cols-2">
              <div class="sm:col-span-1">
                <dt class="text-sm font-medium text-gray-500">Transportation</dt>
                <dd class="mt-1 text-sm text-gray-900 flex items-center">
                  <.icon name="hero-check-circle" class="text-green-500 w-5 h-5 mr-2" /> Independent
                </dd>
              </div>
              <div class="sm:col-span-1">
                <dt class="text-sm font-medium text-gray-500">Housing</dt>
                <dd class="mt-1 text-sm text-gray-900 flex items-center">
                  <.icon name="hero-exclamation-circle" class="text-red-500 w-5 h-5 mr-2" />
                  Unstable / Rent Burden
                </dd>
              </div>
              <div class="sm:col-span-1">
                <dt class="text-sm font-medium text-gray-500">Insurance</dt>
                <dd class="mt-1 text-sm text-gray-900">Medicare Primary / Pending Secondary</dd>
              </div>
              <div class="sm:col-span-1">
                <dt class="text-sm font-medium text-gray-500">Employment</dt>
                <dd class="mt-1 text-sm text-gray-900">Unemployed (Disability Applied)</dd>
              </div>
            </dl>
          </div>
        </div>

        <div class="bg-white shadow sm:rounded-lg">
          <div class="px-4 py-5 sm:px-6 border-b border-gray-200">
            <h3 class="text-base font-semibold leading-6 text-gray-900">Psychosocial & Support</h3>
          </div>
          <div class="px-4 py-5 sm:p-6">
            <div class="space-y-6">
              <div>
                <h4 class="text-sm font-medium text-gray-900">PHQ-9 Depression Screen</h4>
                <div class="mt-2 w-full bg-gray-200 rounded-full h-2.5">
                  <div class="bg-yellow-400 h-2.5 rounded-full" style="width: 45%"></div>
                </div>
                <p class="mt-1 text-xs text-gray-500">Score: 9/20 (Mild Depression)</p>
              </div>

              <div class="border-t border-gray-100 pt-4">
                <h4 class="text-sm font-medium text-gray-900 mb-2">Care Partner Status</h4>
                <div class="rounded-md bg-blue-50 p-4">
                  <div class="flex">
                    <div class="shrink-0">
                      <.icon name="hero-information-circle" class="h-5 w-5 text-blue-400" />
                    </div>
                    <div class="ml-3 flex-1 md:flex md:justify-between">
                      <p class="text-sm text-blue-700">
                        Spouse reported high fatigue during last clinic visit.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-8 bg-white shadow sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <h3 class="text-base font-semibold leading-6 text-gray-900">Social Work Notes</h3>
        </div>
        <div class="px-4 py-5 sm:p-6">
          <div class="relative">
            <label for="comment" class="sr-only">Add your note</label>
            <textarea
              rows="3"
              name="comment"
              id="comment"
              class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-purple-600 sm:text-sm sm:leading-6"
              placeholder="Add a case note..."
            ></textarea>
            <div class="absolute bottom-0 right-0 flex justify-between py-2 pl-3 pr-2">
              <div class="flex items-center space-x-5"></div>
              <button
                type="submit"
                class="inline-flex items-center rounded-md bg-purple-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-purple-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-purple-600"
              >
                Add Note
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
