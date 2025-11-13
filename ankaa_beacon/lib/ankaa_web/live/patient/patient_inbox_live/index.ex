defmodule AnkaaWeb.PatientInboxListLive.Index do
  use AnkaaWeb, :patient_layout

  alias Ankaa.Messages

  @impl true
  def mount(_params, _session, socket) do
    patient = socket.assigns.current_user.patient

    # Subscribe to new message broadcasts
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Ankaa.PubSub, "patient:#{patient.id}:messages")
    end

    # Fetch all existing messages
    messages = Messages.list_messages_for_patient(patient.id)

    {:ok,
     assign(socket,
       messages: messages,
       current_path: "/patient/inbox"
     )}
  end

  # When a new message is broadcast, add it to the top of the list
  @impl true
  def handle_info({:new_message, message}, socket) do
    {:noreply, update(socket, :messages, &[message | &1])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto py-8">
      <h1 class="text-2xl font-bold text-slate-900 mb-8">My Inbox</h1>

      <div class="bg-white shadow overflow-hidden sm:rounded-md">
        <ul role="list" class="divide-y divide-gray-200">
          <%= for message <- @messages do %>
            <li class="p-4 sm:p-6">
              <div class="flex items-start">
                <div class="shrink-0">
                  <span class="inline-flex h-10 w-10 items-center justify-center rounded-full bg-blue-100">
                    <.icon name="hero-chat-bubble-left-right" class="h-6 w-6 text-blue-600" />
                  </span>
                </div>
                <div class="ml-4">
                  <p class="text-sm font-medium text-gray-900">
                    New message from your Care Team
                  </p>
                  <p class="mt-1 text-sm text-gray-700"><%= message.content %></p>
                  <p class="mt-2 text-xs text-gray-500">
                    <%= Timex.format!(message.inserted_at, "{Mfull} {D}, {h12}:{m} {AM}") %>
                  </p>
                </div>
              </div>
            </li>
          <% end %>
          <%= if Enum.empty?(@messages) do %>
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
