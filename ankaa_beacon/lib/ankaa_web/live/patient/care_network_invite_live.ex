defmodule AnkaaWeb.CareNetworkInviteLive do
  use AnkaaWeb, :live_view
  use AnkaaWeb, :patient_layout

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       form: to_form(%{"email" => "", "role" => "family_member"}),
       current_path: "/patient/carenetwork/invite"
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="max-w-3xl mx-auto">
        <div class="bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="px-4 py-5 sm:px-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900">Invite to Care Network</h3>
            <p class="mt-1 max-w-2xl text-sm text-gray-500">
              Invite someone to join your care network. They will receive an email invitation.
            </p>
          </div>
          <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
            <.form for={@form} phx-submit="invite" class="space-y-6">
              <div>
                <label for="email" class="block text-sm font-medium text-gray-700">Email Address</label>
                <div class="mt-1">
                  <input
                    type="email"
                    name="email"
                    id="email"
                    value={@form[:email].value}
                    class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                    placeholder="person@example.com"
                  />
                </div>
              </div>

              <div>
                <label for="role" class="block text-sm font-medium text-gray-700">Role</label>
                <div class="mt-1">
                  <select
                    id="role"
                    name="role"
                    class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  >
                    <option value="family_member">Family Member</option>
                    <option value="caregiver">Caregiver</option>
                    <option value="doctor">Doctor</option>
                    <option value="nurse">Nurse</option>
                    <option value="other">Other</option>
                  </select>
                </div>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700">Permissions</label>
                <div class="mt-2 space-y-2">
                  <div class="flex items-center">
                    <input
                      type="checkbox"
                      name="permissions[]"
                      value="view_health_data"
                      class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                    />
                    <label class="ml-2 block text-sm text-gray-900">View Health Data</label>
                  </div>
                  <div class="flex items-center">
                    <input
                      type="checkbox"
                      name="permissions[]"
                      value="update_medications"
                      class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                    />
                    <label class="ml-2 block text-sm text-gray-900">Update Medications</label>
                  </div>
                  <div class="flex items-center">
                    <input
                      type="checkbox"
                      name="permissions[]"
                      value="schedule_appointments"
                      class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                    />
                    <label class="ml-2 block text-sm text-gray-900">Schedule Appointments</label>
                  </div>
                </div>
              </div>

              <div class="flex justify-end">
                <.link
                  navigate={~p"/patient/carenetwork"}
                  class="px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  Cancel
                </.link>
                <button
                  type="submit"
                  class="ml-3 inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  Send Invitation
                </button>
              </div>
            </.form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event(
        "invite",
        %{"email" => email, "role" => _role, "permissions" => _permissions},
        socket
      ) do
    # In a real app, this would send an email invitation
    # For now, we'll just show a success message
    {:noreply,
     socket
     |> put_flash(:info, "Invitation sent to #{email}")
     |> push_navigate(to: ~p"/patient/carenetwork")}
  end
end
