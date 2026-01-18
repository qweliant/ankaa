defmodule AnkaaWeb.PatientDashboard.Components.CareNetworkComponent do
  @moduledoc """
  Manages the patient's Care Network.
  """
  use AnkaaWeb, :live_component

  alias Ankaa.Patients
  alias Ankaa.Invites
  alias Ankaa.Notifications.Invite

  @impl true
  def update(assigns, socket) do
    network = Patients.get_care_network_for_patient(assigns.patient)
    invite_changeset = Invite.changeset(%Invite{}, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       network: network,
       # State for Modals
       active_modal: nil,
       member_to_manage: nil,

       # Forms
       invite_form: to_form(invite_changeset),
       manage_form: nil
     )}
  end


  @impl true
  def handle_event("open_invite_modal", _, socket) do
    {:noreply, assign(socket, active_modal: :invite)}
  end

  @impl true
  def handle_event("open_manage_modal", %{"id" => id}, socket) do
    member = Patients.get_care_network_member!(id)
    changeset = Ankaa.Patients.CareNetwork.changeset(member, %{})

    {:noreply,
     assign(socket,
       active_modal: :manage,
       member_to_manage: member,
       manage_form: to_form(changeset)
     )}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, assign(socket, active_modal: nil, member_to_manage: nil)}
  end


  @impl true
  def handle_event("send_invite", %{"invite" => invite_params}, socket) do
    current_user = socket.assigns.current_user
    patient = socket.assigns.patient

    case Invites.send_invitation(current_user, patient, invite_params) do
      {:ok, _invite} ->
        {:noreply,
         socket
         |> assign(active_modal: nil)
         |> put_flash(:info, "Invitation sent to #{invite_params["invitee_email"]}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, invite_form: to_form(changeset))}

      {:error, msg} ->
        {:noreply, put_flash(socket, :error, msg)}
    end
  end


  @impl true
  def handle_event("remove_member", %{"id" => id}, socket) do
    member = Patients.get_care_network_member!(id)
    {:ok, _} = Patients.remove_care_network_member(member)

    updated_network = Patients.get_care_network_for_patient(socket.assigns.patient)

    {:noreply,
     socket
     |> assign(active_modal: nil, network: updated_network)
     |> put_flash(:info, "Member removed from network.")}
  end


  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto space-y-8 animate-fade-in-up">

      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-2xl font-bold text-slate-800">Care Network</h2>
          <p class="text-sm text-slate-500">Manage who has access to your health data</p>
        </div>
        <button phx-click="open_invite_modal" phx-target={@myself} class="bg-indigo-600 text-white px-4 py-2 rounded-xl hover:bg-indigo-700 transition font-bold text-sm shadow-md shadow-indigo-200 flex items-center gap-2">
           <.icon name="hero-envelope" class="w-5 h-5" />
           Invite New Member
        </button>
      </div>

      <div class="grid gap-4">
        <%= for member <- @network do %>
          <div class="bg-white p-6 rounded-4xl border border-slate-100 shadow-sm flex items-center justify-between group hover:border-indigo-100 transition-colors">

            <div class="flex items-center gap-4">
              <div class={"h-12 w-12 rounded-full flex items-center justify-center text-lg font-bold
                  #{if member.status == "pending", do: "bg-amber-50 text-amber-600", else: "bg-indigo-50 text-indigo-600"}
              "}>
                 <%= cond do %>
                   <% member.status == "pending" -> %> ⏳
                   <% member.role == "doctor" -> %> 🩺
                   <% member.role == "nurse" -> %> 💉
                   <% true -> %> ❤️
                 <% end %>
              </div>

              <div>
                 <h3 class="font-bold text-slate-800 text-lg flex items-center gap-2">
                   {member.name || member.user.email}
                   <%= if member.status == "pending" do %>
                     <span class="bg-amber-100 text-amber-700 text-[10px] px-2 py-0.5 rounded-full uppercase tracking-wide font-bold">Pending</span>
                   <% end %>
                 </h3>
                 <p class="text-sm text-slate-500 capitalize">{member.role}</p>
              </div>
            </div>

            <%= if member.status == "active" do %>
              <button phx-click="open_manage_modal" phx-value-id={member.id} phx-target={@myself} class="text-sm font-bold text-slate-400 hover:text-indigo-600 border border-slate-200 hover:border-indigo-200 px-4 py-2 rounded-lg transition">
                Manage
              </button>
            <% else %>
               <button phx-click="remove_member" phx-value-id={member.id} phx-target={@myself} data-confirm="Cancel invitation?" class="text-sm font-bold text-rose-400 hover:text-rose-600 px-4 py-2">
                 Cancel Invite
              </button>
            <% end %>
          </div>
        <% end %>

        <%= if Enum.empty?(@network) do %>
           <div class="text-center py-12 bg-slate-50 rounded-4xl border border-dashed border-slate-200">
             <div class="h-12 w-12 bg-white rounded-full flex items-center justify-center mx-auto mb-3 shadow-sm text-slate-300">
               <.icon name="hero-users" class="w-6 h-6" />
             </div>
             <p class="text-slate-500 font-medium">Your network is empty</p>
             <p class="text-slate-400 text-sm">Invite a doctor or family member to get started.</p>
           </div>
        <% end %>
      </div>

      <%= if @active_modal == :invite do %>
        <.modal id="invite-modal" show on_cancel={JS.push("close_modal", target: @myself)}>
          <div class="p-6">
            <h3 class="text-lg font-bold text-slate-900 mb-4">Invite to Care Network</h3>
            <.simple_form for={@invite_form} phx-submit="send_invite" phx-target={@myself}>
              <.input field={@invite_form[:invitee_email]} type="email" label="Email Address" placeholder="doctor@example.com" required />
              <.input field={@invite_form[:invitee_role]} type="select" label="Role" options={["Care Support": "caresupport", "Doctor": "doctor", "Nurse": "nurse"]} required />

              <:actions>
                <div class="flex justify-end gap-3 w-full">
                   <button type="button" phx-click="close_modal" phx-target={@myself} class="px-4 py-2 text-slate-600 font-bold hover:bg-slate-50 rounded-lg">Cancel</button>
                   <button type="submit" class="px-6 py-2 bg-indigo-600 text-white font-bold rounded-lg hover:bg-indigo-700">Send Invitation</button>
                </div>
              </:actions>
            </.simple_form>
          </div>
        </.modal>
      <% end %>

      <%= if @active_modal == :manage do %>
        <.modal id="manage-modal" show on_cancel={JS.push("close_modal", target: @myself)}>
          <div class="p-6">
            <div class="text-center mb-6">
              <div class="h-16 w-16 bg-indigo-50 text-indigo-600 rounded-full flex items-center justify-center mx-auto mb-3">
                <span class="text-2xl">👤</span>
              </div>
              <h3 class="text-xl font-bold text-slate-900">
                {@member_to_manage.user.first_name} {@member_to_manage.user.last_name}
              </h3>
              <p class="text-sm text-slate-500 capitalize">
                Role: {@member_to_manage.role}
              </p>
            </div>

            <div class="border-t border-slate-100 pt-6">
              <p class="text-sm text-slate-600 mb-4 text-center">
                Do you want to remove this person from your care network? They will no longer have access to your data.
              </p>

              <div class="flex flex-col gap-3">
                <button type="button" phx-click="remove_member" phx-value-id={@member_to_manage.id} phx-target={@myself} data-confirm="Are you sure? This cannot be undone."
                  class="w-full py-3 bg-rose-50 hover:bg-rose-100 text-rose-600 font-bold rounded-xl transition">
                  Remove from Network
                </button>
                <button type="button" phx-click="close_modal" phx-target={@myself}
                  class="w-full py-3 text-slate-500 font-bold hover:bg-slate-50 rounded-xl transition">
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </.modal>
      <% end %>

    </div>
    """
  end
end
