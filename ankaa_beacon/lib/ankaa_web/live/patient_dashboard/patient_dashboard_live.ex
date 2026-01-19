defmodule AnkaaWeb.PatientDashboardLive do
  use AnkaaWeb, :live_view
  use AnkaaWeb, :alert_handling

  alias Ankaa.Patients
  alias Ankaa.Devices
  alias Ankaa.Accounts

  alias AnkaaWeb.PatientDashboard.Components.ClinicalCommandComponent
  alias AnkaaWeb.PatientDashboard.Components.FamilyPeaceComponent
  alias AnkaaWeb.PatientDashboard.Components.CaseworkerNotebookComponent
  alias AnkaaWeb.PatientDashboard.Components.PatientSelfComponent

  require Logger

  @impl true
  def mount(%{"patient_id" => patient_id}, _session, socket) do
    user = socket.assigns.current_user
    patient = Patients.get_patient!(patient_id)
    devices = Devices.list_devices_for_patient(patient.id)
    contacts = Ankaa.Accounts.list_available_contacts(user)

    # TODO: Add security check here later (Patients.can_access?)
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Ankaa.PubSub, "user:#{user.id}:messages")
      Phoenix.PubSub.subscribe(Ankaa.PubSub, "patient:#{patient.id}:devicereading")
    end

    view_type =
      cond do
        Accounts.patient?(user) and user.patient.id == patient.id ->
          :patient_self

        Accounts.doctor?(user) or Accounts.nurse?(user) or Accounts.clinic_technician?(user) ->
          :clinical

        Accounts.has_role?(user, "social_worker") ->
          :social

        Accounts.caresupport?(user) ->
          :family

        true ->
          :unknown
      end

    {
      :ok,
      assign(socket,
        patient: patient,
        current_user: user,
        user_role: user.role,
        page_title: "#{patient.name} - Dashboard",
        view_type: view_type,
        has_vitals_permission: true,
        devices: devices,
        bp_readings: [],
        dialysis_readings: [],
        bp_violations: [],
        dialysis_violations: [],
        contacts: contacts,
        show_chat: false
      )
    }
  end

  @impl true
  def handle_event("toggle_chat", _, socket) do
    {:noreply, assign(socket, show_chat: !socket.assigns.show_chat)}
  end

  @impl true
  def handle_event("dismiss_alert", %{"id" => alert_id}, socket) do
    # Call context to dismiss
    case Ankaa.Alerts.dismiss_alert(alert_id, socket.assigns.current_user, "Dismissed by patient") do
      {:ok, _} ->
        # The list updates automatically via PubSub broadcast {:alert_dismissed, id}
        # which is handled by `use AnkaaWeb, :alert_handling`
        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not dismiss alert.")}
    end
  end

  @impl true
  def handle_info({:new_reading, reading, violations}, socket) do
    reading_for_stream =
      reading
      |> Map.from_struct()
      |> Map.put(:id, Ecto.UUID.generate())

    socket =
      case reading do
        %Ankaa.Monitoring.BPDeviceReading{} ->
          socket
          |> assign(:latest_bp, reading)
          |> assign(:bp_violations, violations)
          |> update(:bp_readings, fn list -> [reading | Enum.take(list, 4)] end)

        %Ankaa.Monitoring.DialysisDeviceReading{} ->
          socket
          |> assign(:latest_dialysis, reading)
          |> assign(:dialysis_violations, violations)
          |> update(:dialysis_readings, fn list -> [reading | Enum.take(list, 4)] end)

        _ ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    # 1. (Optional) Log it so you can see it working in the terminal
    require Logger
    Logger.info("📨 Real-time message received: #{message.content}")

    # 2. Pass the message to the Inbox Component
    # CRITICAL: The `id` here ("main-inbox") MUST match the ID in your HTML render
    send_update(AnkaaWeb.Chat.InboxComponent, id: "main-inbox", new_message_event: message)

    # 3. (Optional) Play a sound or show a generic toast if chat is closed
    socket =
      if !socket.assigns.show_chat do
        put_flash(socket, :info, "New message from #{message.sender.first_name}")
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:mood_updated, _entry}, socket) do
    {:noreply, put_flash(socket, :info, "Daily check-in saved successfully!")}
  end

  @impl true
  def handle_info(:refresh_devices, socket) do
    updated_devices = Devices.list_devices_for_patient(socket.assigns.patient.id)
    {:noreply, assign(socket, devices: updated_devices)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 relative">
      <main class="mx-auto max-w-[98%] py-6 sm:px-6 lg:px-8">
        <div class="fixed bottom-6 right-6 z-50">
          <button
            phx-click="toggle_chat"
            class="bg-purple-600 hover:bg-purple-700 text-white p-4 rounded-full shadow-lg border-4 border-purple-500 transition-transform hover:scale-105 flex items-center justify-center"
          >
            <%= if @show_chat do %>
              <.icon name="hero-x-mark" class="w-8 h-8" />
            <% else %>
              <.icon name="hero-chat-bubble-left-right" class="w-8 h-8" />
            <% end %>
          </button>
        </div>

        <%= if @show_chat do %>
          <div
            class="fixed inset-0 z-40 overflow-hidden"
            aria-labelledby="slide-over-title"
            role="dialog"
            aria-modal="true"
          >
            <div class="absolute inset-0 overflow-hidden">
              <div
                class="absolute inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
                phx-click="toggle_chat"
              >
              </div>

              <div class="pointer-events-none fixed inset-y-0 right-0 flex max-w-full pl-10">
                <div class="pointer-events-auto w-screen max-w-md">
                  <div class="flex h-full flex-col overflow-y-scroll bg-white shadow-xl">
                    <div class="px-4 py-6 sm:px-6 bg-purple-600">
                      <div class="flex items-start justify-between">
                        <h2 class="text-lg font-medium text-white" id="slide-over-title">Messages</h2>
                        <div class="ml-3 flex h-7 items-center">
                          <button
                            type="button"
                            phx-click="toggle_chat"
                            class="rounded-md bg-purple-600 text-purple-200 hover:text-white focus:outline-none"
                          >
                            <span class="sr-only">Close panel</span>
                            <.icon name="hero-x-mark" class="h-6 w-6" />
                          </button>
                        </div>
                      </div>
                    </div>

                    <div class="relative flex-1 py-6 px-4 sm:px-6 h-full">
                      <.live_component
                        module={AnkaaWeb.Chat.InboxComponent}
                        id="main-inbox"
                        current_user={@current_user}
                        contacts={@contacts}
                      />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        <% end %>
        <%= case @view_type do %>
          <% :clinical -> %>
            <.live_component
              module={ClinicalCommandComponent}
              id="clinical"
              patient={@patient}
              current_user={@current_user}
              active_alerts={@active_alerts}
              bp_readings={@bp_readings}
              dialysis_readings={@dialysis_readings}
              devices={@devices}
            />
          <% :family -> %>
            <.live_component
              module={FamilyPeaceComponent}
              id="family"
              patient={@patient}
              current_user={@current_user}
              devices={@devices}
              has_vitals_permission={@has_vitals_permission}
              bp_readings={@bp_readings}
              dialysis_readings={@dialysis_readings}
            />
          <% :social -> %>
            <.live_component
              module={CaseworkerNotebookComponent}
              id="social"
              patient={@patient}
              current_user={@current_user}
            />
          <% :patient_self -> %>
            <.live_component
              module={PatientSelfComponent}
              id="self"
              patient={@patient}
              current_user={@current_user}
              devices={@devices}
              bp_readings={@bp_readings}
              dialysis_readings={@dialysis_readings}
            />
          <% _ -> %>
            <div class="text-center py-12">
              <h3 class="mt-2 text-sm font-semibold text-gray-900">Access Denied</h3>
              <p class="mt-1 text-sm text-gray-500">
                You do not have permission to view this dashboard.
              </p>
            </div>
        <% end %>
      </main>
    </div>
    """
  end
end
