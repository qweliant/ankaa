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
    <div class="flex flex-col h-full bg-white relative">
      <div class="flex-1 overflow-hidden flex flex-col">
        <%= if @is_composing do %>
        <% else %>
          <%= if @active_conversation do %>
            <div class="flex flex-col h-full">
              <div class="border-b px-4 py-3 flex items-center bg-gray-50/50">
                <button
                  phx-click="close_conversation"
                  phx-target={@myself}
                  class="mr-3 text-slate-500 hover:text-purple-600 transition"
                >
                  <.icon name="hero-arrow-left" class="w-5 h-5" />
                </button>
                <div>
                  <h3 class="font-bold text-slate-800 text-sm">
                    {@active_conversation.partner.first_name} {@active_conversation.partner.last_name}
                  </h3>
                  <p class="text-[10px] text-slate-400 uppercase tracking-wider font-semibold">
                    Online
                  </p>
                </div>
              </div>

              <div
                id="chat-messages"
                phx-hook="ScrollToBottom"
                class="flex-1 overflow-y-auto p-4 space-y-3 flex flex-col-reverse scroll-smooth"
              >
                <%= for msg <- @active_conversation.messages do %>
                  <div class={"flex mb-2 #{if msg.sender_id == @current_user.id, do: "justify-end", else: "justify-start"}"}>
                    <div class={"max-w-[80%] px-4 py-2 text-sm shadow-sm #{
                      if msg.sender_id == @current_user.id,
                      do: "bg-purple-600 text-white rounded-2xl rounded-tr-sm",
                      else: "bg-white border border-slate-100 text-slate-700 rounded-2xl rounded-tl-sm"
                    }"}>
                      {msg.content}
                    </div>
                  </div>
                <% end %>

                <%= if Enum.empty?(@active_conversation.messages) do %>
                  <div class="flex-1 flex items-center justify-center">
                    <p class="text-slate-300 text-sm italic">No messages yet. Say hello!</p>
                  </div>
                <% end %>
              </div>

              <div class="p-3 border-t bg-white">
                <.simple_form
                  for={@message_form}
                  phx-submit="send_message"
                  phx-target={@myself}
                  class="relative"
                >
                  <div class="flex gap-2 items-center">
                    <div class="flex-1 relative">
                      <.input
                        field={@message_form[:content]}
                        type="text"
                        placeholder="Type a message..."
                        class="w-full pr-10 rounded-full border-slate-200 focus:border-purple-500 focus:ring-purple-500"
                        autocomplete="off"
                      />
                    </div>
                    <button
                      type="submit"
                      class="bg-purple-600 hover:bg-purple-700 text-white p-2.5 rounded-full shadow-md shadow-purple-200 transition-transform hover:scale-105 active:scale-95"
                    >
                      <.icon name="hero-paper-airplane" class="w-5 h-5 -ml-0.5" />
                    </button>
                  </div>
                </.simple_form>
              </div>
            </div>
          <% else %>
            <ul class="divide-y divide-gray-50 overflow-y-auto">
              <%= for convo <- @conversations do %>
                <li
                  phx-click="select_conversation"
                  phx-value-partner-id={convo.partner.id}
                  phx-target={@myself}
                  class="p-4 hover:bg-purple-50 cursor-pointer transition-colors group"
                >
                  <div class="flex justify-between items-start">
                    <div class="flex items-center gap-3">
                      <div class="relative">
                        <div class="h-12 w-12 rounded-full bg-slate-100 flex items-center justify-center text-slate-500 font-bold border border-slate-200 group-hover:border-purple-200 group-hover:bg-white group-hover:text-purple-600 transition-colors">
                          {String.at(convo.partner.first_name, 0)}
                        </div>
                        <div class="absolute bottom-0 right-0 h-3 w-3 bg-emerald-500 rounded-full border-2 border-white">
                        </div>
                      </div>
                      <div>
                        <p class="font-bold text-slate-800 text-sm">
                          {convo.partner.first_name} {convo.partner.last_name}
                        </p>
                        <p class={"text-xs truncate w-40 #{if convo.unread_count > 0, do: "font-bold text-slate-900", else: "text-slate-500"}"}>
                          {convo.latest_message.content}
                        </p>
                      </div>
                    </div>
                    <%= if convo.unread_count > 0 do %>
                      <div class="flex flex-col items-end gap-1">
                        <span class="text-[10px] text-slate-400">
                          {Calendar.strftime(convo.latest_message.inserted_at, "%H:%M")}
                        </span>
                        <span class="bg-purple-600 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full min-w-[1.25rem] text-center shadow-sm shadow-purple-200">
                          {convo.unread_count}
                        </span>
                      </div>
                    <% end %>
                  </div>
                </li>
              <% end %>
            </ul>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  # Handles real-time updates passed from Parent LiveView
  defp handle_incoming_message(socket, message) do
    current_active = socket.assigns.active_conversation
    current_user_id = socket.assigns.current_user.id

    # Scenario A: We are currently looking at the chat with the sender
    if current_active && current_active.partner.id == message.sender_id do
      # 1. Mark read instantly
      Messages.mark_messages_as_read(current_user_id, message.sender_id)

      # 2. Add to list (PREPENDING because we use flex-col-reverse)
      updated_active = Map.update!(current_active, :messages, &[message | &1])

      # 3. Play a tiny sound effect? (Optional via JS hook later)
      assign(socket, active_conversation: updated_active)

      # Scenario B: We are looking at a different chat or the list
    else
      # 1. Refresh the conversation list to update the "Unread" badge and "Last Message" snippet
      new_conversations = Messages.list_conversations_for_user(current_user_id)

      socket
      |> assign(conversations: new_conversations)
      # Optional Toast
      |> put_flash(:info, "New message from #{message.sender_id}!")
    end
  end
end
