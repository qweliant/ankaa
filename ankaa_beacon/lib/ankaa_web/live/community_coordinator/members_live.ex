defmodule AnkaaWeb.Community.MembersLive do
  use AnkaaWeb, :live_view

  alias Ankaa.Communities

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    if user.organization_id do
      org = Communities.get_organization!(user.organization_id)
      members = Communities.list_members(org.id)

      {:ok,
       assign(socket,
         org: org,
         members: members,
         page_title: "Manage Members"
       )}
    else
      {:ok, redirect(socket, to: ~p"/")}
    end
  end

  @impl true
  def handle_event("remove_member", %{"id" => user_id}, socket) do
    member_to_remove = Communities.get_member!(user_id)

    # Prevent removing self!
    if member_to_remove.id == socket.assigns.current_user.id do
      {:noreply, put_flash(socket, :error, "You cannot remove yourself from the community.")}
    else
      case Communities.remove_member(member_to_remove) do
        {:ok, _} ->
          # Refresh list
          {:noreply,
           socket
           |> put_flash(:info, "Member removed from community.")
           |> assign(members: Communities.list_members(socket.assigns.org.id))}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to remove member.")}
      end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-10">

      <div class="md:flex md:items-center md:justify-between mb-8">
        <div class="min-w-0 flex-1">
          <div class="mb-4">
            <.link navigate={~p"/community/dashboard"} class="text-sm font-medium text-gray-500 hover:text-gray-700 flex items-center">
              <.icon name="hero-arrow-left" class="w-4 h-4 mr-1"/> Back to Hub
            </.link>
          </div>

          <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:truncate sm:text-3xl sm:tracking-tight">
            Community Members
          </h2>
          <p class="mt-1 text-sm text-gray-500">
            People currently joined to <span class="font-semibold">{@org.name}</span>
          </p>
        </div>
        <div class="mt-4 flex md:ml-4 md:mt-0">
           <span class="inline-flex items-center rounded-md bg-purple-50 px-2 py-1 text-xs font-medium text-purple-700 ring-1 ring-inset ring-purple-700/10">
             {length(@members)} Members
           </span>
        </div>
      </div>

      <div class="bg-white shadow-sm ring-1 ring-gray-900/5 sm:rounded-xl overflow-hidden">
        <table class="min-w-full divide-y divide-gray-300">
          <thead class="bg-gray-50">
            <tr>
              <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6">Name</th>
              <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Role</th>
              <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Joined</th>
              <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-6">
                <span class="sr-only">Actions</span>
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200 bg-white">
            <%= for member <- @members do %>
              <tr>
                <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm sm:pl-6">
                  <div class="flex items-center">
                    <div class="h-10 w-10 shrink-0 rounded-full bg-gray-100 flex items-center justify-center text-gray-500 font-bold">
                      {String.slice(member.first_name || member.email, 0, 1) |> String.upcase()}
                    </div>
                    <div class="ml-4">
                      <div class="font-medium text-gray-900">
                        {if member.first_name, do: "#{member.first_name} #{member.last_name}", else: "Unknown Name"}
                      </div>
                      <div class="text-gray-500">{member.email}</div>
                    </div>
                  </div>
                </td>
                <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                  <span class={[
                    "inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset",
                    case member.role do
                      "patient" -> "bg-blue-50 text-blue-700 ring-blue-700/10"
                      "community_coordinator" -> "bg-purple-50 text-purple-700 ring-purple-700/10"
                      _ -> "bg-gray-50 text-gray-600 ring-gray-500/10"
                    end
                  ]}>
                    {String.capitalize(member.role || "Member")}
                  </span>
                </td>
                <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                  {Calendar.strftime(member.inserted_at, "%b %d, %Y")}
                </td>
                <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6">
                  <%= if member.id != @current_user.id do %>
                    <button
                      phx-click="remove_member"
                      phx-value-id={member.id}
                      data-confirm={"Are you sure you want to remove #{member.email} from the community?"}
                      class="text-red-600 hover:text-red-900"
                    >
                      Remove
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
