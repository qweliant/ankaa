defmodule AnkaaWeb.Community.Components.MembersComponent do
  @moduledoc """
  This component handles the display and management of community members within a specific organization.
  It allows coordinators to view all members, their roles, and invite new members via email.
  It also provides the functionality to remove members (except self-removal) for coordinators.
  """
  use AnkaaWeb, :live_component

  alias Ankaa.Communities
  alias Ankaa.Invites
  alias Ankaa.Notifications.Invite

  @impl true
  def update(assigns, socket) do
    org_id = assigns.org.id
    members = Communities.list_members(org_id)
    invite_changeset = Invite.changeset(%Invite{}, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       members: members,
       invite_form: to_form(invite_changeset),
       show_invite_modal: false
     )}
  end


  @impl true
  def handle_event("toggle_invite", _, socket) do
    {:noreply, assign(socket, show_invite_modal: !socket.assigns.show_invite_modal)}
  end

  @impl true
  def handle_event("send_invite", %{"invite" => params}, socket) do
    attrs = %{
      "invitee_email" => params["invitee_email"],
      "invitee_role" => "patient", # Default role for community members
      "organization_id" => socket.assigns.org.id,
      "inviter_id" => socket.assigns.current_user.id
    }

    case Invites.create_invite(socket.assigns.current_user, attrs) do
      {:ok, _invite} ->
        {:noreply,
         socket
         |> assign(show_invite_modal: false)
         |> put_flash(:info, "Invitation sent to #{attrs["invitee_email"]}.")}

      {:error, changeset} ->
        {:noreply, assign(socket, invite_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("remove_member", %{"user-id" => user_id}, socket) do
    # Security Check: Ensure only coordinator can do this
    if socket.assigns.current_role != "coordinator" do
      {:noreply, put_flash(socket, :error, "Unauthorized.")}
    else
      # Fetch the user struct to remove
      member_user = Communities.get_member!(user_id)

      # Prevent self-removal here (though UI hides button)
      if member_user.id == socket.assigns.current_user.id do
        {:noreply, put_flash(socket, :error, "You cannot remove yourself.")}
      else
        # Use the NEW remove_member/2 function (user, org_id)
        case Communities.remove_member(member_user, socket.assigns.org.id) do
          {count, _} when count > 0 ->
            updated_members = Communities.list_members(socket.assigns.org.id)
            {:noreply, socket |> assign(members: updated_members) |> put_flash(:info, "Member removed.")}

          _ ->
            {:noreply, put_flash(socket, :error, "Failed to remove member.")}
        end
      end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6 animate-fade-in-up">

      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-2xl font-bold text-slate-800">Community Members</h2>
          <p class="text-sm text-slate-500">
            People currently joined to <span class="font-semibold text-purple-600">{@org.name}</span>
          </p>
        </div>

        <div class="flex items-center gap-4">
           <span class="inline-flex items-center rounded-full bg-purple-50 px-3 py-1 text-xs font-bold text-purple-700 border border-purple-100">
             {length(@members)} Members
           </span>

           <%= if @current_role == "coordinator" do %>
             <button phx-click="toggle_invite" phx-target={@myself} class="bg-indigo-600 text-white px-4 py-2 rounded-xl hover:bg-indigo-700 transition font-bold text-sm shadow-md shadow-indigo-200 flex items-center gap-2">
               <.icon name="hero-envelope" class="w-5 h-5" />
               Invite
             </button>
           <% end %>
        </div>
      </div>

      <%= if @show_invite_modal do %>
        <div class="bg-gray-50 p-6 rounded-2xl border border-gray-200">
          <h3 class="font-bold text-slate-800 mb-4">Invite New Member</h3>
          <.simple_form for={@invite_form} phx-submit="send_invite" phx-target={@myself}>
            <div class="flex gap-4 items-end">
              <div class="flex-1">
                <.input field={@invite_form[:invitee_email]} type="email" label="Email Address" placeholder="member@example.com" required />
              </div>
              <div class="pb-2">
                <.button>Send Invite</.button>
              </div>
            </div>
          </.simple_form>
        </div>
      <% end %>

      <div class="bg-white shadow-sm ring-1 ring-gray-900/5 sm:rounded-2xl overflow-hidden">
        <table class="min-w-full divide-y divide-gray-300">
          <thead class="bg-gray-50">
            <tr>
              <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-xs font-bold uppercase tracking-wider text-gray-500 sm:pl-6">Name</th>
              <th scope="col" class="px-3 py-3.5 text-left text-xs font-bold uppercase tracking-wider text-gray-500">Role</th>
              <th scope="col" class="px-3 py-3.5 text-left text-xs font-bold uppercase tracking-wider text-gray-500">Joined</th>
              <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-6">
                <span class="sr-only">Actions</span>
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200 bg-white">
            <%= for row <- @members do %>
              <tr class="group hover:bg-gray-50 transition-colors">

                <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm sm:pl-6">
                  <div class="flex items-center">
                    <div class="h-10 w-10 shrink-0 rounded-full bg-gradient-to-br from-purple-100 to-indigo-100 flex items-center justify-center text-indigo-600 font-bold border border-white shadow-sm">
                      {String.slice(row.user.first_name || row.user.email, 0, 1) |> String.upcase()}
                    </div>
                    <div class="ml-4">
                      <div class="font-bold text-slate-800">
                        {if row.user.first_name, do: "#{row.user.first_name} #{row.user.last_name}", else: "Unknown Name"}
                      </div>
                      <div class="text-slate-500 text-xs">{row.user.email}</div>
                    </div>
                  </div>
                </td>

                <td class="whitespace-nowrap px-3 py-4 text-sm">
                  <span class={[
                    "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-bold capitalize",
                    case row.role do
                      "patient" -> "bg-blue-50 text-blue-700 border border-blue-100"
                      "coordinator" -> "bg-purple-50 text-purple-700 border border-purple-100"
                      _ -> "bg-gray-50 text-gray-600 border border-gray-100"
                    end
                  ]}>
                    {row.role || "Member"}
                  </span>
                </td>

                <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                  {Calendar.strftime(row.joined_at, "%b %d, %Y")}
                </td>

                <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6">
                  <%= if @current_role == "coordinator" and row.user.id != @current_user.id do %>
                    <button
                      phx-click="remove_member"
                      phx-value-user-id={row.user.id}
                      phx-target={@myself}
                      data-confirm={"Are you sure you want to remove #{row.user.email}?"}
                      class="text-slate-300 hover:text-rose-600 transition-colors"
                      title="Remove Member"
                    >
                      <.icon name="hero-trash" class="w-5 h-5" />
                    </button>
                  <% end %>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>

    </div>
    """
  end
end
