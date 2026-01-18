defmodule AnkaaWeb.Chat.InboxComponent do
  @moduledoc """
  A reusable Chat Inbox component.
  It handles listing conversations, selecting a chat, and sending messages.
  It relies on the Parent LiveView to handle PubSub subscriptions and pass down
  new messages via send_update/3.
  """

  require Logger

  use AnkaaWeb, :live_component

  alias Ankaa.Messages
  alias Ankaa.Accounts

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:active_conversation, fn -> nil end)
      |> assign_new(:message_form, fn ->
        to_form(Messages.change_message(%Ankaa.Notifications.Message{}))
      end)
      |> assign_new(:is_composing, fn -> false end)
      |> assign_new(:conversations, fn ->
        Messages.list_conversations_for_user(assigns.current_user.id)
      end)

    socket =
      if Map.has_key?(assigns, :new_message_event) do
        handle_incoming_message(socket, assigns.new_message_event)
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("select_conversation", %{"partner-id" => partner_id}, socket) do
    current_user_id = socket.assigns.current_user.id
    messages = Messages.get_messages_between(current_user_id, partner_id)
    Messages.mark_messages_as_read(current_user_id, partner_id)
    partner = Accounts.get_user!(partner_id)

    updated_conversations =
      Enum.map(socket.assigns.conversations, fn convo ->
        if convo.partner.id == partner_id do
          %{convo | unread_count: 0}
        else
          convo
        end
      end)

    {:noreply,
     assign(socket,
       active_conversation: %{partner: partner, messages: messages},
        conversations: updated_conversations,
        is_composing: false
     )}
  end

  @impl true
  def handle_event("close_conversation", _, socket) do
    {:noreply, assign(socket, active_conversation: nil)}
  end

  @impl true
  def handle_event("send_message", %{"message" => params}, socket) do
    current_user = socket.assigns.current_user
    partner = socket.assigns.active_conversation.partner

    message_params = %{
      content: params["content"],
      sender_id: current_user.id,
      recipient_id: partner.id,
      read: false
    }

    case Messages.create_message(message_params) do
      {:ok, message} ->
        # Optimistically append the message to the current view
        updated_active =
          Map.update!(socket.assigns.active_conversation, :messages, fn msgs ->
            [message | msgs]
          end)

        # Reset form
        new_form = to_form(Messages.change_message(%Ankaa.Notifications.Message{}))

        {:noreply,
         assign(socket,
           active_conversation: updated_active,
           message_form: new_form
         )}

      {:error, changeset} ->
        Logger.error("Message failed to send: #{inspect(changeset.errors)}")
        {:noreply, put_flash(socket, :error, "Failed to send message")}
    end
  end

  @impl true
  def handle_event("show_compose", _, socket) do
    # Switch to compose view
    {:noreply, assign(socket, is_composing: true, active_conversation: nil)}
  end

  @impl true
  def handle_event("cancel_compose", _, socket) do
    # Go back to list
    {:noreply, assign(socket, is_composing: false)}
  end

  @impl true
  def handle_event("start_new_chat", %{"recipient_id" => recipient_id}, socket) do
    existing_convo =
      Enum.find(socket.assigns.conversations, fn c ->
        c.partner.id == recipient_id
      end)

    if existing_convo do
      send(self(), {"select_conversation", %{"partner-id" => recipient_id}})
      {:noreply, assign(socket, is_composing: false)}
    else
      partner = Accounts.get_user!(recipient_id)

      empty_convo = %{
        partner: partner,
        messages: []
      }

      {:noreply,
       assign(socket,
         active_conversation: empty_convo,
         is_composing: false
       )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-full bg-white">
      <%= if !@active_conversation and !@is_composing do %>
        <div class="flex justify-between items-center mb-4 px-2">
          <h3 class="text-lg font-bold text-gray-900">Inbox</h3>
          <button
            phx-click="show_compose"
            phx-target={@myself}
            class="text-purple-600 hover:text-purple-800 text-sm font-semibold flex items-center gap-1"
          >
            <.icon name="hero-pencil-square" class="w-5 h-5" /> New
          </button>
        </div>
      <% end %>

      <div class="flex-1 overflow-y-auto">
        <%= if @is_composing do %>
          <div class="p-2">
            <div class="flex items-center mb-4">
              <button phx-click="cancel_compose" phx-target={@myself} class="mr-2 text-gray-500">
                <.icon name="hero-arrow-left" class="w-5 h-5" />
              </button>
              <h3 class="font-bold">New Message</h3>
            </div>

            <p class="text-sm text-gray-500 mb-2">Select a recipient:</p>
            <ul class="divide-y divide-gray-100 border rounded-lg">
              <%= for contact <- @contacts do %>
                <li
                  class="hover:bg-gray-50 p-3 cursor-pointer flex items-center gap-3"
                  phx-click="start_new_chat"
                  phx-value-recipient_id={contact.id}
                  phx-target={@myself}
                >
                  <div class="h-8 w-8 rounded-full bg-purple-100 flex items-center justify-center text-purple-700 text-xs font-bold">
                    {String.at(contact.first_name || "?", 0)}
                  </div>
                  <span>{contact.first_name} {contact.last_name}</span>
                </li>
              <% end %>
            </ul>
          </div>
        <% else %>
          <%= if @active_conversation do %>
            <div class="flex flex-col h-full">
              <div class="border-b pb-2 mb-2 flex items-center">
                <button
                  phx-click="close_conversation"
                  phx-target={@myself}
                  class="mr-2 text-gray-500 hover:text-gray-700"
                >
                  <.icon name="hero-arrow-left" class="w-5 h-5" />
                </button>
                <span class="font-bold">
                  {@active_conversation.partner.first_name} {@active_conversation.partner.last_name}
                </span>
              </div>

              <div class="flex-1 overflow-y-auto space-y-3 p-2 flex flex-col-reverse">
                <%= for msg <- @active_conversation.messages do %>
                  <div class={"flex #{if to_string(msg.sender_id) == to_string(@current_user.id), do: "justify-end", else: "justify-start"}"}>
                    <div class={"max-w-[85%] px-3 py-2 rounded-lg text-sm #{
                      if msg.sender_id == @current_user.id,
                      do: "bg-purple-600 text-white rounded-br-none",
                      else: "bg-gray-100 text-gray-800 rounded-bl-none"
                    }"}>
                      {msg.content}
                    </div>
                  </div>
                <% end %>
                <%= if Enum.empty?(@active_conversation.messages) do %>
                  <p class="text-center text-gray-400 text-sm mt-10">Start the conversation...</p>
                <% end %>
              </div>

              <div class="mt-2 pt-2 border-t">
                <.simple_form
                  for={@message_form}
                  phx-submit="send_message"
                  phx-target={@myself}
                  class="flex gap-2"
                >
                  <div class="flex-1">
                    <.input
                      field={@message_form[:content]}
                      type="text"
                      placeholder="Message..."
                      class="mt-0!"
                    />
                  </div>
                  <button type="submit" class="bg-purple-600 text-white p-2 rounded-lg">
                    <.icon name="hero-paper-airplane" class="w-5 h-5" />
                  </button>
                </.simple_form>
              </div>
            </div>
          <% else %>
            <ul class="divide-y divide-gray-100">
              <%= for convo <- @conversations do %>
                <li
                  phx-click="select_conversation"
                  phx-value-partner-id={convo.partner.id}
                  phx-target={@myself}
                  class="p-3 hover:bg-gray-50 cursor-pointer rounded-lg transition"
                >
                  <div class="flex justify-between items-start">
                    <div class="flex items-center gap-3">
                      <div class="h-10 w-10 rounded-full bg-gray-200 flex items-center justify-center text-gray-600 font-bold">
                        {String.at(convo.partner.first_name, 0)}
                      </div>
                      <div>
                        <p class="font-medium text-gray-900">{convo.partner.first_name}</p>
                        <p class="text-xs text-gray-500 truncate w-32">
                          {convo.latest_message.content}
                        </p>
                      </div>
                    </div>
                    <%= if convo.unread_count > 0 do %>
                      <span class="bg-purple-600 text-white text-[10px] px-2 py-0.5 rounded-full">
                        {convo.unread_count}
                      </span>
                    <% end %>
                  </div>
                </li>
              <% end %>
              <%= if Enum.empty?(@conversations) do %>
                <li class="text-center text-gray-500 py-8">No messages yet.</li>
              <% end %>
            </ul>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  defp load_conversations(user) do
    # Assuming you have a generic context function.
    # If not, you might need to check user role and call specific context.
    Messages.list_conversations_for_user(user.id)
  end

  # Handles real-time updates passed from Parent LiveView
  defp handle_incoming_message(socket, message) do
    current_active = socket.assigns.active_conversation

    # 1. If we are currently chatting with the sender, append the message
    if current_active && current_active.partner.id == message.sender_id do
      # Mark read since we are looking at it
      Messages.mark_messages_as_read(socket.assigns.current_user.id, message.sender_id)

      updated_active = Map.update!(current_active, :messages, &[message | &1])
      assign(socket, active_conversation: updated_active)

      # 2. If we are not chatting with them, just refresh the conversation list to show badges/latest text
    else
      conversations = load_conversations(socket.assigns.current_user)
      assign(socket, conversations: conversations)
    end
  end
end
