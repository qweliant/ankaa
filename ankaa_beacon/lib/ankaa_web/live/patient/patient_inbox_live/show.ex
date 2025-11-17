defmodule AnkaaWeb.PatientInboxListLive.Show do
  use AnkaaWeb, :patient_layout

  alias Ankaa.Messages
  alias Ankaa.Accounts

  @impl true
  def mount(%{"id" => sender_id}, _session, socket) do
    patient = socket.assigns.current_user.patient

    messages = Messages.get_messages_from_sender(patient.id, sender_id)
    sender = Accounts.get_user!(sender_id)

    Messages.mark_messages_as_read(patient.id, sender_id)

    {:ok,
     assign(socket,
       messages: messages,
       sender: sender,
       sender_id: sender_id,
       current_path: "/patient/inbox"
     )}
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    if message.sender_id == socket.assigns.sender_id do
      Messages.mark_messages_as_read(
        socket.assigns.current_user.patient.id,
        socket.assigns.sender_id
      )

      {:noreply, update(socket, :messages, &[message | &1])}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto py-8">
      <div class="mb-8">
        <.link
          navigate={~p"/patient/inbox"}
          class="inline-flex items-center text-sm font-medium text-gray-500 hover:text-gray-700"
        >
          <.icon name="hero-arrow-left" class="h-5 w-5 mr-2" /> Back to Inbox
        </.link>
      </div>

      <h1 class="text-2xl font-bold text-slate-900 mb-8">
        Messages from {@sender.first_name} {@sender.last_name}
      </h1>

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
                  <p class="text-sm text-gray-700">{message.content}</p>
                  <p class="mt-2 text-xs text-gray-500">
                    {Timex.format!(message.inserted_at, "{Mfull} {D}, {h12}:{m} {AM}")}
                  </p>
                </div>
              </div>
            </li>
          <% end %>
          <%= if Enum.empty?(@messages) do %>
            <li class="p-4 sm:p-6 text-center text-gray-500">
              You have no messages from this sender.
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end
end
