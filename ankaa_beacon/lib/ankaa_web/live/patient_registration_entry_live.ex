defmodule AnkaaWeb.PatientRegistrationEntryLive do
  use AnkaaWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Register as Patient")
     |> assign(:registration_url, ~p"/register-patient/patient")}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-50">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="max-w-md mx-auto">
          <div class="bg-white shadow rounded-lg p-6">
            <h1 class="text-2xl font-bold text-slate-900 mb-4">Register as Patient</h1>

            <p class="text-slate-600 mb-6">
              To register as a patient, you'll need to provide some basic information about yourself.
              This will help us create your patient profile and connect you with your healthcare providers.
            </p>

            <div class="space-y-4">
              <div class="bg-slate-50 p-4 rounded-lg">
                <h2 class="font-semibold text-slate-900 mb-2">What you'll need:</h2>
                <ul class="list-disc list-inside text-slate-600 space-y-1">
                  <li>Your full name</li>
                  <li>Date of birth</li>
                  <li>Your timezone</li>
                </ul>
              </div>

              <div class="pt-4">
                <.link
                  href={@registration_url}
                  class="inline-flex items-center justify-center w-full px-4 py-2 border border-transparent text-base font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  Start Registration
                </.link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
