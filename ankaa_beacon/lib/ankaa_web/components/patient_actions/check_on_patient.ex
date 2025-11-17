defmodule AnkaaWeb.CheckInButton do
  @moduledoc """
  A LiveComponent that renders a "Check-In" button for caregivers to send a passive
  check-in message to  patients. Once clicked, the button changes to a
  confirmation message.
  """
  use AnkaaWeb, :live_component

  alias Ankaa.Messages
  alias Ankaa.Patients

  require Logger

  @doc """
  Mounts the component, assigning the patient and current user.
  """
  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       sent: false
     )}
  end

  @doc """
  Renders the "Check-In" button or a "Sent!" confirmation.
  """
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @sent do %>
        <span class="inline-flex items-center rounded-lg bg-green-100 px-4 py-2 font-semibold text-green-700">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 20 20"
            fill="currentColor"
            class="h-5 w-5 mr-2"
          >
            <path
              fill-rule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z"
              clip-rule="evenodd"
            />
          </svg>
          Check-in sent!
        </span>
      <% else %>
        <button
          class="inline-flex items-center rounded-lg bg-blue-500 px-4 py-2 font-semibold text-white shadow-md hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-opacity-75
                 disabled:opacity-50 disabled:cursor-not-allowed"
          phx-click="send_check_in"
          phx-target={@myself}
          phx-disable-with="Sending..."
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 20 20"
            fill="currentColor"
            class="h-5 w-5 mr-2"
          >
            <path d="M3.105 2.288a.75.75 0 00-.826.95l1.414 4.925A1.5 1.5 0 005.135 9.25h6.115a.75.75 0 010 1.5H5.135a1.5 1.5 0 00-1.442 1.087l-1.414 4.925a.75.75 0 00.95.826l16-5.25a.75.75 0 000-1.352l-16-5.25z" />
          </svg>
          Send "Checking In" Ping
        </button>
      <% end %>
    </div>
    """
  end

  @doc """
  Handles the button click, creates the message, and updates the component state.
  """
  @impl true
  def handle_event("send_check_in", _params, socket) do
    caregiver = socket.assigns.current_user
    patient_id = socket.assigns.patient.id
    patient = Patients.get_patient!(patient_id)

    case Messages.send_passive_check_in(patient, caregiver) do
      {:ok, _} ->
        {:noreply, assign(socket, :sent, true)}

      {:error, _} ->
        put_flash(socket, :error, "Failed to send passive check-in")
        {:noreply, socket}
    end
  end
end
