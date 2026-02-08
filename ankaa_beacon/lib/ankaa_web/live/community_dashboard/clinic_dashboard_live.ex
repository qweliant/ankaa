defmodule AnkaaWeb.ClinicDashboardLive do
  use AnkaaWeb, :live_view

  alias Ankaa.Communities
  alias Ankaa.Patients
  alias Ankaa.Accounts

  @impl true
  def mount(%{"community_id" => org_id}, _session, socket) do
    user = socket.assigns.current_user

    case Communities.get_user_role_in_org(user, %Ankaa.Community.Organization{id: org_id}) do
      nil ->
        {:ok, redirect(socket, to: ~p"/portal")}

      role ->
        roster = Communities.list_patients_for_organization(org_id)
        org = Communities.get_organization!(org_id)

        {:ok,
         assign(socket,
           current_role: role,
           active_org: org,
           roster: roster,
           patient_filter: "",
           active_tab: :roster,
           show_add_patient_modal: false,
           add_form: to_form(%{"email" => "", "mrn" => ""})
         )}
    end
  end

  @impl true
  def handle_event("filter_patients", %{"query" => query}, socket) do
    {:noreply, assign(socket, patient_filter: String.downcase(query))}
  end

  @impl true
  def handle_event("toggle_add_patient", _, socket) do
    {:noreply, assign(socket, show_add_patient_modal: !socket.assigns.show_add_patient_modal)}
  end

  @impl true
  def handle_event("save_patient_to_roster", %{"email" => email, "mrn" => mrn}, socket) do
    email = String.trim(email)

    case Accounts.get_user_by_email(email) do
      nil ->
        {:noreply, put_flash(socket, :error, "User not found. They must register first.")}

      user ->
        case Patients.get_patient_by_user_id(user.id) do
          nil ->
            {:noreply,
             put_flash(socket, :error, "User exists but has no Patient Profile set up.")}

          patient ->
            case Communities.add_patient_to_organization(
                   patient.id,
                   socket.assigns.active_org.id,
                   mrn
                 ) do
              {:ok, _} ->
                # Refresh Roster
                updated_roster =
                  Communities.list_patients_for_organization(socket.assigns.active_org.id)

                {:noreply,
                 socket
                 |> assign(roster: updated_roster, show_add_patient_modal: false)
                 |> put_flash(:info, "#{patient.name} added to roster.")}

              {:error, _} ->
                {:noreply,
                 put_flash(socket, :error, "Could not add patient. Might already be in roster.")}
            end
        end
    end
  end

  defp filter_roster(roster, "") do
    roster
  end

  defp filter_roster(roster, query) do
    Enum.filter(roster, fn {p, mrn} ->
      name_match = String.contains?(String.downcase(p.name), query)
      mrn_match = mrn && String.contains?(String.downcase(mrn), query)
      name_match or mrn_match
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-50 flex flex-col">
      <header class="bg-white border-b border-slate-200 sticky top-0 z-20 px-6 py-4 flex items-center justify-between">
        <div class="flex items-center gap-4">
          <div class="h-10 w-10 bg-purple-600 rounded-lg flex items-center justify-center text-white font-bold text-xl">
            {String.slice(@active_org.name, 0, 1)}
          </div>
          <div>
            <h1 class="text-lg font-bold text-slate-900 leading-tight">{@active_org.name}</h1>
            <p class="text-xs font-medium text-slate-500 uppercase tracking-wider">
              Clinical Workspace
            </p>
          </div>
        </div>

        <div class="flex items-center gap-3">
          <.link
            href={~p"/c/#{@active_org.id}/community"}
            class="text-sm font-medium text-slate-500 hover:text-purple-600"
          >
            Community View &rarr;
          </.link>
        </div>
      </header>

      <main class="flex-1 p-6 max-w-7xl mx-auto w-full">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div class="bg-white p-5 rounded-2xl shadow-sm border border-slate-100">
            <p class="text-xs font-bold text-slate-400 uppercase">Total Patients</p>
            <p class="text-3xl font-black text-slate-800">{length(@roster)}</p>
          </div>
          <div class="bg-white p-5 rounded-2xl shadow-sm border border-slate-100">
            <% alert_count = Enum.count(@roster, fn {p, _} -> length(p.alerts) > 0 end) %>
            <p class="text-xs font-bold text-rose-400 uppercase">Patients with Alerts</p>
            <p class="text-3xl font-black text-rose-600">{alert_count}</p>
          </div>
          <div class="bg-gradient-to-br from-purple-600 to-indigo-600 p-5 rounded-2xl shadow-md text-white">
            <p class="text-xs font-bold text-purple-200 uppercase">My Shift</p>
            <p class="text-lg font-bold">On Duty</p>
            <p class="text-xs text-purple-200 mt-1">Dr. {@current_user.last_name}</p>
          </div>
        </div>

        <div class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
          <div class="p-4 border-b border-slate-100 flex items-center justify-between">
            <h2 class="text-lg font-bold text-slate-800">Patient Roster</h2>
            <form phx-change="filter_patients" onsubmit="return false;">
              <input
                type="text"
                name="query"
                placeholder="Search name or MRN..."
                class="text-sm border-slate-300 rounded-lg focus:ring-purple-500 focus:border-purple-500 w-64"
              />
            </form>
          </div>

          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-slate-50">
              <tr>
                <th
                  scope="col"
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Patient
                </th>
                <th
                  scope="col"
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Status
                </th>
                <th
                  scope="col"
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Active Alerts
                </th>
                <th
                  scope="col"
                  class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <%= for {patient, mrn} <- filter_roster(@roster, @patient_filter) do %>
                <tr class="hover:bg-slate-50 transition-colors group">
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="flex items-center">
                      <div class="h-10 w-10 rounded-full bg-slate-100 flex items-center justify-center text-slate-500 font-bold">
                        {String.slice(patient.name, 0, 1)}
                      </div>
                      <div class="ml-4">
                        <div class="text-sm font-bold text-gray-900">{patient.name}</div>
                        <div class="text-xs text-gray-500">MRN: {mrn || "N/A"}</div>
                      </div>
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                      Active
                    </span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <%= if length(patient.alerts) > 0 do %>
                      <span class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800 animate-pulse">
                        <.icon name="hero-bell-alert-solid" class="w-3 h-3" />
                        {length(patient.alerts)} Critical
                      </span>
                    <% else %>
                      <span class="text-xs text-slate-400 flex items-center gap-1">
                        <.icon name="hero-check-circle" class="w-4 h-4" /> Normal
                      </span>
                    <% end %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <.link
                      href={~p"/p/#{patient.id}/dashboard"}
                      class="text-purple-600 hover:text-purple-900 font-bold flex items-center justify-end gap-1 group-hover:underline"
                    >
                      Open Chart <.icon name="hero-arrow-right" class="w-3 h-3" />
                    </.link>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>

          <%= if @roster == [] do %>
            <div class="p-12 text-center text-slate-500">
              <p>No patients assigned to this clinic yet.</p>
              <button phx-click="toggle_add_patient" class="mt-4 text-purple-600 font-bold hover:underline">
                Add Patient
              </button>
            </div>
          <% end %>
        </div>
      </main>
      <.modal
      :if={@show_add_patient_modal}
      id="add-patient-modal"
      show
      on_cancel={JS.push("toggle_add_patient")}
    >
      <.header>
        Add Patient to Roster
        <:subtitle>Enter the patient's email to link them to {@active_org.name}.</:subtitle>
      </.header>

      <form phx-submit="save_patient_to_roster" class="mt-6 space-y-4">
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">Patient Email</label>
          <input
            type="email"
            name="email"
            required
            placeholder="patient@example.com"
            class="w-full rounded-lg border-slate-300 focus:border-purple-500 focus:ring-purple-500"
          />
          <p class="text-xs text-slate-500 mt-1">User must already be registered in Ankaa.</p>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">MRN (Optional)</label>
          <input
            type="text"
            name="mrn"
            placeholder="Clinic Record Number"
            class="w-full rounded-lg border-slate-300 focus:border-purple-500 focus:ring-purple-500"
          />
        </div>

        <div class="mt-6 flex justify-end gap-3">
          <button
            type="button"
            phx-click="toggle_add_patient"
            class="px-4 py-2 text-sm font-medium text-slate-700 hover:text-slate-900"
          >
            Cancel
          </button>
          <button
            type="submit"
            class="px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white text-sm font-bold rounded-xl shadow-lg shadow-purple-200 transition-all"
          >
            Add to Roster
          </button>
        </div>
      </form>
    </.modal>
    </div>
    """
  end
end
