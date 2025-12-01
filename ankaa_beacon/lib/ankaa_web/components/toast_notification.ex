defmodule AnkaaWeb.ToastNotification do
  @moduledoc """
  A LiveComponent that displays toast notifications for users.
  It shows different content based on whether the user is a patient or caregiver.
  """
  use AnkaaWeb, :live_component

  @doc "Renders the toast if a message is present."
  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed bottom-0 right-0 z-50 p-4 sm:p-8">
      <%= if @toast_message do %>
        <%!--
          This is the toast container.
          - `phx-mounted` triggers the entry animation.
          - `phx-remove` (from handle_event) will trigger the exit.
        --%>
        <div
          id="toast-notification"
          class="relative max-w-sm w-full rounded-2xl bg-white p-5 shadow-2xl ring-1 ring-black ring-opacity-5 transition-all transform-gpu"
          phx-mounted={
            JS.show(
              transition:
                {"ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
                 "opacity-100 translate-y-0 sm:scale-100"}
            )
          }
          phx-remove={JS.hide(transition: {"ease-in duration-200", "opacity-100", "opacity-0"})}
        >
          <%= if @current_user.patient do %>
            <.patient_toast_content toast_message={@toast_message} myself={@myself} />
          <% else %>
            <.caregiver_toast_content toast_message={@toast_message} myself={@myself} />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  attr :toast_message, :map, required: true
  attr :myself, :any, required: true
  defp patient_toast_content(assigns) do
    ~H"""
    <div class="flex items-start">
      <div class="shrink-0">
        <span class="inline-flex h-11 w-11 items-center justify-center rounded-full bg-blue-100 text-blue-600">
          <.icon name="hero-chat-bubble-left-right" class="h-6 w-6" />
        </span>
      </div>
      <div class="ml-4 flex-1">
        <p class="text-base font-medium text-gray-900">
          New Check-In
        </p>
        <p class="mt-1 text-sm text-gray-700">
          {@toast_message.content}
        </p>

        <div class="mt-4 flex gap-3">
          <button
            type="button"
            class="flex-1 inline-flex items-center justify-center rounded-lg bg-green-500 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-green-600"
            phx-click="send_check_in_reply"
            phx-value-message_id={@toast_message.id}
            phx-value-status="ok"
            phx-disable-with="Sending..."
          >
            <.icon name="hero-check" class="-ml-0.5 mr-2 h-5 w-5" /> I'm Good
          </button>

          <button
            type="button"
            class="flex-1 inline-flex items-center justify-center rounded-lg bg-red-100 px-3 py-2 text-sm font-semibold text-red-700 shadow-sm hover:bg-red-200"
            phx-click="send_check_in_reply"
            phx-value-message_id={@toast_message.id}
            phx-value-status="not_ok"
            phx-disable-with="Escalating..."
          >
            <.icon name="hero-exclamation-triangle" class="-ml-0.5 mr-2 h-5 w-5" /> Not Feeling Well
          </button>
        </div>
      </div>
      <.dismiss_button target={@myself} />
    </div>
    """
  end

  attr :toast_message, :map, required: true
  attr :myself, :any, required: true
  defp caregiver_toast_content(assigns) do
    ~H"""
    <div class="flex items-start">
      <div class="shrink-0">
        <span class="inline-flex h-11 w-11 items-center justify-center rounded-full bg-green-100 text-green-600">
          <.icon name="hero-check-circle" class="h-7 w-7" />
        </span>
      </div>
      <div class="ml-4 flex-1">
        <p class="text-base font-medium text-gray-900">
          Patient Replied
        </p>
        <p class="mt-1 text-sm text-gray-700">
          {@toast_message.content}
        </p>
        <div class="mt-4 flex">
          <button
            type="button"
            class="inline-flex w-full items-center justify-center rounded-lg bg-gray-100 px-4 py-2 text-sm font-semibold text-gray-700 shadow-sm hover:bg-gray-200"
            phx-click="dismiss_toast"
          >
            Got it, thanks!
          </button>
        </div>
      </div>
      <.dismiss_button target={@myself} />
    </div>
    """
  end

  attr :target, :any, required: true

  defp dismiss_button(assigns) do
    ~H"""
    <button
      type="button"
      class="absolute top-3 right-3 rounded-full p-1 text-gray-400 hover:bg-gray-100 hover:text-gray-500"
      phx-click="dismiss_toast"
      aria-label="Dismiss"
    >
      <.icon name="hero-x-mark" class="h-5 w-5" />
    </button>
    """
  end
end
