defmodule AnkaaWeb.PatientInboxListLive.Index do
  use AnkaaWeb, :patient_layout

  alias Ankaa.Messages

  @impl true
  def mount(_params, _session, socket) do
    patient = socket.assigns.current_user.patient
    # Fetch all existing messages
    conversations = Messages.list_conversations_for_patient(patient.id)

    {:ok,
     assign(socket,
       conversations: conversations,
       current_path: "/patient/inbox"
     )}
  end

  # When a new message is broadcast, add it to the top of the list
  @impl true
  def handle_info({:new_message, _message}, socket) do
    patient = socket.assigns.current_user.patient
    conversations = Messages.list_conversations_for_patient(patient.id)
    {:noreply, assign(socket, :conversations, conversations)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto py-8">
      <h1 class="text-2xl font-bold text-slate-900 mb-8">My Inbox</h1>

      <div class="bg-white shadow overflow-hidden sm:rounded-md">
        <ul role="list" class="divide-y divide-gray-200">
          <%= for convo <- @conversations do %>
            <.link
              navigate={~p"/patient/inbox/#{convo.sender.id}"}
              class="block hover:bg-gray-50 cursor-pointer"
            >
              <li class="p-4 sm:p-6 block hover:bg-gray-50 cursor-pointer">
                <div class="flex items-center">
                  <div class="w-8 shrink-0">
                    <%= if convo.unread_count > 0 do %>
                      <span class="inline-block h-3 w-3 rounded-full bg-blue-500" title="Unread">
                      </span>
                    <% end %>
                  </div>

                  <div class="ml-0 flex-1">
                    <div class="flex justify-between items-center">
                      <p class="text-sm font-medium text-gray-900">
                        {convo.sender.first_name} {convo.sender.last_name}
                      </p>
                      <p class="text-xs text-gray-500">
                        {Timex.format!(convo.latest_message.inserted_at, "{Mfull} {D}")}
                      </p>
                    </div>

                    <p class="mt-1 text-sm text-gray-700 truncate">
                      {convo.latest_message.content}
                    </p>
                  </div>

                  <%= if convo.unread_count > 0 do %>
                    <div class="ml-4">
                      <span class="inline-flex items-center justify-center h-6 w-6 rounded-full bg-blue-500 text-xs font-medium text-white">
                        {convo.unread_count}
                      </span>
                    </div>
                  <% end %>
                </div>
              </li>
            </.link>
          <% end %>

          <%= if Enum.empty?(@conversations) do %>
            <li class="p-4 sm:p-6 text-center text-gray-500">
              You have no messages.
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end
end
