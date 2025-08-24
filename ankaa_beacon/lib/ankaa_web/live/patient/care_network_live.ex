defmodule AnkaaWeb.CareNetworkLive do
  use AnkaaWeb, :patient_layout
  use AnkaaWeb, :alert_handling

  alias Ankaa.Patients

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    patient = user.patient

    network_members =
      if patient do
        Patients.get_care_network_for_patient(patient)
      else
        []
      end

      {:ok,
     assign(socket,
       network: network_members,
       current_path: "/patient/carenetwork",
       show_modal: false,
       selected_member_id: nil,
       member_in_modal: nil,
       member_form: nil
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="flex items-center justify-between mb-8">
        <h1 class="text-2xl font-bold text-slate-900">Care Network</h1>
        <.link
          navigate={~p"/patient/carenetwork/invite"}
          class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          Invite Member
        </.link>
      </div>

      <div class="bg-white shadow overflow-hidden sm:rounded-lg">
        <ul role="list" class="divide-y divide-gray-200">
          <%= for member <- @network do %>
            <li>
              <div class="px-4 py-4 sm:px-6">
                <div class="flex items-center justify-between">
                  <div class="flex items-center">
                    <div class="flex-shrink-0">
                      <span class={[
                        "inline-block h-3 w-3 rounded-full",
                        case member.status do
                          "active" -> "bg-green-400"
                          "pending" -> "bg-yellow-400"
                        end
                      ]}></span>
                    </div>
                    <div class="ml-3">
                      <p class="text-sm font-medium text-gray-900"><%= member.name %></p>
                      <p class="text-sm text-gray-500"><%= member.role |> String.capitalize() %></p>
                    </div>
                  </div>

                  <%= if member.status == "active" do %>
                    <div class="flex items-center space-x-4">
                      <button
                        phx-click="show_modal"
                        phx-value-id={member.id}
                        class="text-indigo-600 hover:text-indigo-900 text-sm font-medium"
                      >
                        Manage
                      </button>
                    </div>
                  <% end %>
                </div>
              </div>
            </li>
          <% end %>
        </ul>
      </div>

      <%= if @show_modal do %>
        <.modal id="member-modal" show>
          <div class="p-6">
            <.simple_form for={@member_form} phx-submit="save_changes">
              <h3 class="text-lg font-medium text-gray-900">
                Manage <%= @member_in_modal.user.first_name %>'s Permissions
              </h3>
              <div class="mt-4">
                <.input
                  field={@member_form[:permissions]}
                  type="checkbox"
                  label="Permissions"
                  options={[
                    {"Receive Alerts", "receive_alerts"},
                    {"Manage Care Network", "manage_network"},
                    {"View Vitals", "view_vitals"}
                  ]}
                />
              </div>
              <div class="mt-6 flex justify-between">
                <button
                  type="button"
                  phx-click="delete_member"
                  phx-value-id={@member_in_modal.id}
                  data-confirm="Are you sure you want to remove this member from your care network?"
                  class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700"
                >
                  Remove Member
                </button>
                <div class="flex space-x-3">
                  <button type="button" phx-click="close_modal" class="px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50">
                    Cancel
                  </button>
                  <.button phx-disable-with="Saving...">Save Changes</.button>
                </div>
              </div>
            </.simple_form>
          </div>
        </.modal>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("show_modal", %{"id" => id}, socket) do
    member = Patients.get_care_network_member!(id)
    changeset = Ankaa.Patients.CareNetwork.changeset(member, %{})

    {:noreply,
     assign(socket,
       show_modal: true,
       selected_member_id: id,
       member_in_modal: member,
       member_form: to_form(changeset)
     )}
  end

  def handle_event("close_modal", _, socket) do
    {:noreply, assign(socket, show_modal: false)}
  end

  def handle_event("save_changes", %{"care_network" => params}, socket) do
    member = socket.assigns.member_in_modal

    case Patients.update_care_network_member(member, params) do
      {:ok, _updated_member} ->
        network =
          Patients.get_care_network_for_patient(socket.assigns.current_user.patient.id)
        {:noreply,
         socket
         |> assign(show_modal: false, network: network)
         |> put_flash(:info, "Member permissions updated.")}

      {:error, changeset} ->
        {:noreply, assign(socket, member_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete_member", %{"id" => member_id}, socket) do
    member = Patients.get_care_network_member!(member_id)
    {:ok, _} = Patients.remove_care_network_member(member)

    # Refetch the network list to show the changes
    network = Patients.get_care_network_for_patient(socket.assigns.current_user.patient.id)

    {:noreply,
     socket
     |> assign(show_modal: false, network: network)
     |> put_flash(:info, "Member removed from your care network.")}
  end
end
