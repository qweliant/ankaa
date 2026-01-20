defmodule AnkaaWeb.PatientDashboard.Components.ClinicalCommandComponent do
  @moduledoc """
  Clinical command center view for doctors, nurses, and clinic technicians.
  Displays patient vitals, treatment plan, and allows for quick actions like
  editing the treatment plan or contacting the care team.
  """
  use AnkaaWeb, :live_component

  alias Ankaa.Patients
  alias Ankaa.Sessions
  alias Ankaa.Patients.TreatmentPlan
  alias Ankaa.Alerts
  alias Ankaa.Messages

  require Logger
  @impl true
  def update(%{patient: patient, current_user: current_user} = assigns, socket) do
    socket =
      if Map.has_key?(socket.assigns, :latest_session) do
        socket
      else
        assign(socket,
          latest_session: Sessions.get_latest_session_for_patient(patient),
          recent_sessions: Sessions.list_sessions_for_patient(patient.id),
          treatment_plan:
            Patients.get_treatment_plan(patient.id) || %TreatmentPlan{patient_id: patient.id},
          care_team: Patients.list_care_team(patient.id)
        )
      end

    latest_session = Sessions.get_latest_session_for_patient(patient)
    available_colleagues = Patients.list_available_colleagues(current_user, patient.id)
    age = calculate_age(patient.date_of_birth)

    prepare_readings = fn readings ->
      Enum.map(readings || [], fn reading ->
        id = "#{reading.device_id}-#{DateTime.to_unix(reading.timestamp, :millisecond)}"

        reading
        |> Map.from_struct()
        |> Map.put(:id, id)
      end)
    end

    {status, last_session} =
      case latest_session do
        %Sessions.Session{status: s, start_time: st} -> {String.capitalize(s), st}
        nil -> {"No Sessions", nil}
      end

    vitals = %{
      blood_pressure: "135/88 mmHg",
      heart_rate: "82 bpm",
      oxygen_saturation: "97%",
      last_updated: DateTime.utc_now() |> DateTime.add(-15, :minute)
    }

    patient_alerts =
      if assigns[:active_alerts] do
        Enum.filter(assigns.active_alerts, fn item ->
          item.alert.patient_id == patient.id and
            item.alert.status == "active" and
            item.alert.severity in ["medium", "high", "critical"]
        end)
      else
        []
      end

    socket =
      if Map.has_key?(socket.assigns, :plan_form) do
        socket
      else
        assign(socket,
          plan_form: to_form(Patients.change_treatment_plan(socket.assigns.treatment_plan)),
          team_form: to_form(%{"user_id" => ""}),
          editing_plan: false
        )
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       age: age,
       status: status,
       last_session: last_session,
       vitals: vitals,
       show_chat: false,
       available_colleagues: available_colleagues,
       patient_alerts: patient_alerts
     )
     |> assign(:bp_readings, prepare_readings.(assigns[:bp_readings]))
     |> assign(:dialysis_readings, prepare_readings.(assigns[:dialysis_readings]))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-[98%] mx-auto px-2 sm:px-4 lg:px-6 py-8">
      <% my_membership = Enum.find(@care_team, fn m -> m.user_id == @current_user.id end)

      my_role = if my_membership, do: my_membership.role, else: @current_user.role

      can_manage_team? =
        @current_user.role in ["admin", "contributor", "owner"] or
          @patient.user_id == @current_user.id or
          @current_user.role in ["doctor", "nurse", "clinic_technician"] %>
      <div class="sm:flex sm:items-center sm:justify-between">
        <div class="sm:flex-auto flex items-center gap-2">
          <div>
            <h1 class="text-xl font-semibold text-gray-900">Patient Details: {@patient.name}</h1>
            <p class="mt-2 text-sm text-gray-700">
              Age: {@age} | Status: {@status}
            </p>
          </div>
        </div>
      </div>
      <%= if @patient_alerts != [] do %>
        <div class="mb-8 rounded-lg border-l-4 border-rose-500 bg-white shadow-md overflow-hidden animate-in fade-in slide-in-from-top-2">
          <div class="px-6 py-4 border-b border-gray-100 bg-rose-50 flex justify-between items-center">
            <h3 class="text-lg font-bold text-rose-700 flex items-center gap-2">
              <.icon name="hero-bell-alert" class="w-6 h-6" />
              Active Risks ({length(@patient_alerts)})
            </h3>
          </div>
          <div class="divide-y divide-gray-100">
            <%= for item <- @patient_alerts do %>
              <div class="px-6 py-4 flex items-center justify-between">
                <div>
                  <div class="flex items-center gap-2">
                    <span class="text-sm font-bold text-gray-900 uppercase">{item.alert.type}</span>
                    <span class={[
                      "inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset",
                      case item.alert.severity do
                        "critical" -> "bg-red-50 text-red-700 ring-red-600/20"
                        "high" -> "bg-orange-50 text-orange-700 ring-orange-600/20"
                        _ -> "bg-yellow-50 text-yellow-800 ring-yellow-600/20"
                      end
                    ]}>
                      {String.capitalize(item.alert.severity)}
                    </span>
                  </div>
                  <p class="text-sm text-gray-600 mt-1">{item.alert.message}</p>
                  <p class="text-xs text-gray-400 mt-1">
                    Detected: {Calendar.strftime(item.alert.inserted_at, "%b %d at %H:%M")}
                  </p>
                </div>

                <div>
                  <%= if item.alert.status != "acknowledged" do %>
                    <button
                      phx-click="acknowledge_alert"
                      phx-value-id={item.alert.id}
                      phx-target={@myself}
                      class="bg-rose-100 text-rose-800 px-4 py-2 rounded-lg text-sm font-bold hover:bg-rose-200 border border-rose-200 shadow-sm transition-all"
                    >
                      Acknowledge & Notify
                    </button>
                  <% else %>
                    <span class="text-xs font-bold bg-gray-100 text-gray-600 px-3 py-1 rounded-full border border-gray-200">
                      Acknowledged
                    </span>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
      <div class="mt-8 grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div class="bg-white shadow rounded-lg p-6">
          <h2 class="text-lg font-medium text-gray-900">Overview</h2>
          <dl class="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div>
              <dt class="text-sm font-medium text-gray-500">Last Session Status</dt>
              <dd class="mt-1">
                <span class={status_badge_color(@status)}>
                  {@status}
                </span>
              </dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Last Session Start</dt>
              <dd class="mt-1 text-sm text-gray-900">
                {if @last_session, do: Calendar.strftime(@last_session, "%Y-%m-%d %H:%M"), else: "N/A"}
              </dd>
            </div>
          </dl>
        </div>

        <div class="bg-white shadow rounded-lg p-6">
          <h2 class="text-lg font-medium text-gray-900">Current Vitals</h2>
          <p class="text-xs text-gray-400">
            Last updated: {Calendar.strftime(@vitals.last_updated, "%H:%M")}
          </p>
          <dl class="mt-4 grid grid-cols-3 gap-4">
            <div>
              <dt class="text-sm font-medium text-gray-500">Blood Pressure</dt>
              <dd class="mt-1 text-sm text-gray-900">{@vitals.blood_pressure}</dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Heart Rate</dt>
              <dd class="mt-1 text-sm text-gray-900">{@vitals.heart_rate}</dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">O₂ Saturation</dt>
              <dd class="mt-1 text-sm text-gray-900">{@vitals.oxygen_saturation}</dd>
            </div>
          </dl>
        </div>

        <div class="bg-white shadow rounded-lg p-6 lg:col-span-2">
          <div class="overflow-hidden flex flex-col h-full">
            <div class="flex justify-between items-center mb-6">
              <h2 class="text-lg font-medium text-gray-900">Real-time Telemetry</h2>
              <%= if @status == "Ongoing" do %>
                <span class="relative flex h-3 w-3">
                  <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75">
                  </span>
                  <span class="relative inline-flex rounded-full h-3 w-3 bg-emerald-500"></span>
                </span>
              <% else %>
                <span class="text-xs text-gray-400">Offline</span>
              <% end %>
            </div>

            <div class="space-y-8">
              <% latest_map = List.first(@bp_readings) %>
              <.live_component
                module={AnkaaWeb.Monitoring.BPComponent}
                id="bp-chart"
                latest={latest_map}
                readings={@bp_readings}
                devices={@devices}
              />
              <% latest_map = List.first(@dialysis_readings) %>
              <.live_component
                module={AnkaaWeb.Monitoring.DialysisComponent}
                id="dialysis-chart"
                latest={latest_map}
                readings={@dialysis_readings}
                devices={@devices}
              />
            </div>
          </div>
        </div>

        <div class="bg-white shadow rounded-lg p-6 lg:col-span-3 mt-8">
          <h2 class="text-lg font-medium text-gray-900 mb-4">Care Team</h2>

          <div class="flow-root mb-6">
            <ul role="list" class="-my-5 divide-y divide-gray-200">
              <%= for member <- @care_team do %>
                <li class="py-4">
                  <div class="flex items-center space-x-4">
                    <div class="shrink-0">
                      <span class="inline-flex h-10 w-10 items-center justify-center rounded-full bg-gray-100 text-gray-500">
                        {String.slice(member.user.email, 0, 2) |> String.upcase()}
                      </span>
                    </div>
                    <%= if member.user.role in ["caresupport"] do %>
                      <span class="inline-flex items-center rounded-md bg-blue-50 px-2 py-1 text-xs font-medium text-blue-700 ring-1 ring-inset ring-blue-700/10">
                        Family
                      </span>
                    <% else %>
                      <span class="inline-flex items-center rounded-md bg-purple-50 px-2 py-1 text-xs font-medium text-purple-700 ring-1 ring-inset ring-purple-700/10">
                        Clinical
                      </span>
                    <% end %>
                    <div class="min-w-0 flex-1">
                      <p class="truncate text-sm font-medium text-gray-900">
                        {member.user.first_name} {member.user.last_name}
                      </p>
                      <p class="truncate text-sm text-gray-500">
                        {String.capitalize(member.relationship || member.user.role)} • {member.user.email}
                      </p>
                    </div>
                    <div class="flex items-center justify-between p-3">
                      <% is_me = member.user_id == @current_user.id
                      is_patient = member.user_id == @patient.user_id

                      can_remove_this_person? = (can_manage_team? and not is_patient) or is_me %>

                      <%= if can_remove_this_person? do %>
                        <button
                          phx-click="remove_team_member"
                          phx-value-id={member.id}
                          phx-target={@myself}
                          data-confirm={
                            if is_me,
                              do: "Are you sure you want to leave the care team?",
                              else: "Remove this member?"
                          }
                          class="text-red-500 hover:text-red-700 text-xs font-bold transition-colors"
                        >
                          {if is_me, do: "Leave", else: "Remove"}
                        </button>
                      <% end %>
                    </div>
                  </div>
                </li>
              <% end %>
            </ul>
          </div>

          <div class="bg-gray-50 p-4 rounded-md">
            <h3 class="text-sm font-medium text-gray-900 mb-2">Add Colleague to Patient</h3>
            <form phx-submit="add_team_member" class="flex gap-3">
              <input
                type="email"
                name="email"
                placeholder="Enter colleague's email..."
                required
                class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-purple-600 sm:text-sm sm:leading-6"
              />
              <button
                type="submit"
                class="rounded-md bg-purple-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-purple-500"
              >
                Add
              </button>
            </form>
            <p class="text-xs text-gray-500 mt-2">
              User must already have an account. If not, <.link
                navigate={~p"/careprovider/patient/new"}
                class="text-purple-600 underline"
              >invite them first</.link>.
            </p>
          </div>
        </div>

        <div class="bg-white shadow rounded-lg p-6 lg:col-span-2 relative">
          <div class="flex justify-between items-center mb-4">
            <h2 class="text-lg font-medium text-gray-900">Treatment Plan</h2>

            <%= if !@editing_plan do %>
              <button
                phx-click="edit_plan"
                class="text-sm text-purple-600 hover:text-purple-900 font-medium flex items-center"
              >
                <.icon name="hero-pencil-square" class="w-4 h-4 mr-1" /> Edit
              </button>
            <% end %>
          </div>

          <%= if @editing_plan do %>
            <.simple_form for={@plan_form} phx-submit="save_plan" class="mt-0">
              <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
                <.input field={@plan_form[:frequency]} label="Frequency" placeholder="e.g. 3x/week" />
                <.input field={@plan_form[:duration_minutes]} label="Duration (min)" type="number" />
                <.input
                  field={@plan_form[:blood_flow_rate]}
                  label="Blood Flow (ml/min)"
                  type="number"
                />
                <.input
                  field={@plan_form[:dialysate_flow_rate]}
                  label="Dialysate Flow (ml/min)"
                  type="number"
                />
                <.input
                  field={@plan_form[:dry_weight]}
                  label="Dry Weight (kg)"
                  type="number"
                  step="0.1"
                />
                <.input
                  field={@plan_form[:target_ultrafiltration]}
                  label="Target UF (L)"
                  type="number"
                  step="0.1"
                />
                <.input
                  field={@plan_form[:access_type]}
                  label="Access Type"
                  type="select"
                  options={["Fistula", "Graft", "CVC"]}
                />
              </div>

              <div class="mt-4">
                <.input field={@plan_form[:notes]} label="Clinical Notes" type="textarea" rows="3" />
              </div>

              <div class="mt-6 flex justify-end gap-3 border-t pt-4">
                <button
                  type="button"
                  phx-click="cancel_edit"
                  class="text-sm font-semibold text-gray-600 hover:text-gray-800"
                >
                  Cancel
                </button>
                <.button>Save Changes</.button>
              </div>
            </.simple_form>
          <% else %>
            <dl class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
              <div>
                <dt class="text-sm font-medium text-gray-500">Frequency</dt>
                <dd class="mt-1 text-sm font-semibold text-gray-900">
                  {@treatment_plan.frequency || "-"}
                </dd>
              </div>
              <div>
                <dt class="text-sm font-medium text-gray-500">Duration</dt>
                <dd class="mt-1 text-sm font-semibold text-gray-900">
                  {if @treatment_plan.duration_minutes,
                    do: "#{@treatment_plan.duration_minutes} min",
                    else: "-"}
                </dd>
              </div>
              <div>
                <dt class="text-sm font-medium text-gray-500">Dry Weight</dt>
                <dd class="mt-1 text-sm font-semibold text-gray-900">
                  {if @treatment_plan.dry_weight, do: "#{@treatment_plan.dry_weight} kg", else: "-"}
                </dd>
              </div>
              <div>
                <dt class="text-sm font-medium text-gray-500">Access Type</dt>
                <dd class="mt-1 text-sm font-semibold text-gray-900">
                  {@treatment_plan.access_type || "-"}
                </dd>
              </div>

              <div class="pt-2 border-t sm:col-span-2 lg:col-span-4 grid grid-cols-2 lg:grid-cols-4 gap-4">
                <div>
                  <dt class="text-xs font-medium text-gray-500 uppercase">Blood Flow</dt>
                  <dd class="text-sm text-gray-900">{@treatment_plan.blood_flow_rate || "-"}</dd>
                </div>
                <div>
                  <dt class="text-xs font-medium text-gray-500 uppercase">Dialysate Flow</dt>
                  <dd class="text-sm text-gray-900">{@treatment_plan.dialysate_flow_rate || "-"}</dd>
                </div>
                <div>
                  <dt class="text-xs font-medium text-gray-500 uppercase">Target UF</dt>
                  <dd class="text-sm text-gray-900">
                    {@treatment_plan.target_ultrafiltration || "-"}
                  </dd>
                </div>
              </div>

              <div class="sm:col-span-2 lg:col-span-4 bg-gray-50 rounded-md p-3 mt-2">
                <dt class="text-xs font-medium text-gray-500 uppercase tracking-wide">
                  Clinical Notes
                </dt>
                <dd class="mt-1 text-sm text-gray-700 whitespace-pre-wrap">
                  {@treatment_plan.notes || "No notes added."}
                </dd>
              </div>
            </dl>
          <% end %>
        </div>

        <div class="bg-white shadow rounded-lg p-6 lg:col-span-2">
          <h2 class="text-lg font-medium text-gray-900">Recent Sessions</h2>
          <div class="mt-4 -mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
            <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
              <table class="min-w-full divide-y divide-gray-300">
                <thead>
                  <tr>
                    <th
                      scope="col"
                      class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0"
                    >
                      Start Time
                    </th>
                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                      Duration
                    </th>
                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                      Status
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-200">
                  <%= for session <- @recent_sessions do %>
                    <tr>
                      <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm text-gray-900 sm:pl-0">
                        {Calendar.strftime(session.start_time, "%Y-%m-%d %H:%M")}
                      </td>
                      <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                        {format_session_duration(session)}
                      </td>
                      <td class="whitespace-nowrap px-3 py-4 text-sm">
                        <span class={status_badge_color(String.capitalize(session.status))}>
                          {String.capitalize(session.status)}
                        </span>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      <%= if @show_chat do %>
        ...
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("edit_plan", _, socket) do
    {:noreply, assign(socket, editing_plan: true)}
  end

  @impl true
  def handle_event("cancel_edit", _, socket) do
    {:noreply,
     socket
     |> assign(editing_plan: false)
     |> assign(plan_form: to_form(TreatmentPlan.changeset(socket.assigns.treatment_plan, %{})))}
  end

  @impl true
  def handle_event("save_plan", %{"treatment_plan" => params}, socket) do
    # Logic to update/create the plan via Context
    case Patients.update_treatment_plan(
           socket.assigns.treatment_plan,
           params,
           socket.assigns.current_user
         ) do
      {:ok, updated_plan} ->
        {:noreply,
         socket
         |> assign(treatment_plan: updated_plan)
         |> assign(editing_plan: false)
         |> put_flash(:info, "Treatment plan updated.")}

      {:error, changeset} ->
        {:noreply, assign(socket, plan_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("add_team_member", %{"email" => email}, socket) do
    patient = socket.assigns.patient

    case Patients.add_care_team_member_by_email(patient.id, email) do
      {:ok, _association} ->
        # Refresh list
        updated_team = Patients.list_care_team(patient.id)

        {:noreply,
         socket
         |> assign(care_team: updated_team)
         |> put_flash(:info, "Team member added successfully.")
         |> assign(team_form: to_form(%{"email" => ""}))}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, put_flash(socket, :error, "This user is already on the team.")}

      {:error, msg} ->
        {:noreply, put_flash(socket, :error, msg)}
    end
  end

  @impl true
  def handle_event("remove_team_member", %{"id" => id}, socket) do
    membership_to_remove = Patients.get_care_network_member!(id)

    current_user = socket.assigns.current_user
    patient = socket.assigns.patient

    is_admin = current_user.role == "admin"
    is_patient_owner = patient.user_id == current_user.id
    is_self_removal = membership_to_remove.user_id == current_user.id
    is_clinician = current_user.role in ["doctor", "nurse", "clinic_technician"]

    target_is_owner = membership_to_remove.user_id == patient.user_id

    authorized? =
      is_admin or
        is_patient_owner or
        is_self_removal or
        (is_clinician and not target_is_owner)

    if authorized? do
      case Patients.remove_care_network_member(membership_to_remove) do
        {:ok, _deleted_struct} ->
          updated_team = Patients.list_care_team(patient.id)

          msg =
            if is_self_removal, do: "You have left the care team.", else: "Team member removed."

          {:noreply,
           socket
           |> assign(care_team: updated_team)
           |> put_flash(:info, msg)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Database error: Could not remove member.")}
      end
    else
      {:noreply, put_flash(socket, :error, "Unauthorized: You cannot remove this member.")}
    end
  end

  @impl true
  def handle_event("acknowledge_alert", %{"id" => alert_id}, socket) do
    user = socket.assigns.current_user
    patient = socket.assigns.patient

    if user.role in ["doctor", "nurse", "clinic_technician", "social_worker"] do
      alert_struct = Alerts.get_alert!(alert_id)

      case Alerts.acknowledge_critical_alert(alert_struct, user.id) do
        {:ok, _} ->
          Messages.create_message(%{
            sender_id: user.id,
            recipient_id: patient.user_id,
            content:
              "I have reviewed your recent alert and checked your vitals. We will monitor this.",
            read_at: nil
          })

          {:noreply, put_flash(socket, :info, "Alert acknowledged & patient notified.")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to acknowledge alert.")}
      end
    else
      Logger.warning("Non-clinical user #{user.id} attempted to acknowledge alert #{alert_id}")
      {:noreply, put_flash(socket, :error, "Unauthorized.")}
    end
  end

  defp calculate_age(nil), do: "N/A"

  defp calculate_age(date_of_birth) do
    today = Date.utc_today()
    age = today.year - date_of_birth.year

    if {today.month, today.day} < {date_of_birth.month, date_of_birth.day} do
      age - 1
    else
      age
    end
  end

  defp format_session_duration(%Sessions.Session{start_time: start, end_time: stop})
       when not is_nil(stop) do
    diff_seconds = DateTime.diff(stop, start, :second)
    hours = div(diff_seconds, 3600)
    minutes = rem(div(diff_seconds, 60), 60)
    "#{hours}h #{minutes}m"
  end

  defp format_session_duration(_session), do: "Ongoing"

  defp status_badge_color(status) do
    base_classes = "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium"

    color_classes =
      case status do
        "Ongoing" -> "bg-green-100 text-green-800"
        "Completed" -> "bg-blue-100 text-blue-800"
        "Aborted" -> "bg-red-100 text-red-800"
        _ -> "bg-gray-100 text-gray-800"
      end

    "#{base_classes} #{color_classes}"
  end
end
