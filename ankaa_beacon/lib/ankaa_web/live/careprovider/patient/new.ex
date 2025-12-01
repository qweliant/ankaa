defmodule AnkaaWeb.CareProvider.PatientLive.New do
  @moduledoc """
  LiveView for inviting a new patient or care team member.
  """
  use AnkaaWeb, :live_view
  use AnkaaWeb, :alert_handling

  alias Ankaa.Invites
  alias Ankaa.Notifications.Invite
  alias Ankaa.Accounts

  @impl true
  def mount(_params, _session, socket) do
    # We initialize the changeset.
    # Note: We don't need to preset 'invitee_role' here if we use the form input,
    # but setting a default is good UX.
    changeset = Invite.changeset(%Invite{invitee_role: "patient"}, %{})
    {:ok, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("invite_user", %{"invite" => invite_params}, socket) do
    current_user = socket.assigns.current_user
    invitee_email = invite_params["invitee_email"]

    invitee_role = invite_params["invitee_role"] || "patient"

    existing_user = Accounts.get_user_by_email(invitee_email)

    attrs = %{
      "invitee_email" => invitee_email,
      "invitee_role" => invitee_role, # <--- Dynamic Role
      "patient_id" => nil
    }
    Logger.info("Invite attrs: #{inspect(attrs)}")

    cond do
      existing_user && invitee_role == "patient" && Accounts.User.patient?(existing_user) ->
        {:noreply, put_flash(socket, :error, "A user with this email is already registered as a patient.")}

      existing_user && existing_user.role != nil ->
         {:noreply, put_flash(socket, :error, "A user with this email is already registered.")}

      true ->
        case Invites.create_invite(current_user, attrs) do
          {:ok, _invite} ->
            msg = if invitee_role == "patient", do: "Patient invited successfully.", else: "A member of your care team has been invited successfully."

            {:noreply,
             socket
             |> put_flash(:info, "#{msg} Email sent to #{invitee_email}.")
             |> push_navigate(to: ~p"/careprovider/patients")}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, form: to_form(changeset))}
        end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto py-8">
      <.link navigate={~p"/careprovider/patients"} class="text-sm font-semibold text-indigo-600 mb-4 inline-block">
        &larr; Back to Patient List
      </.link>

      <div class="bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900">
            Invite New Member
          </h3>
          <p class="mt-1 max-w-2xl text-sm text-gray-500">
            Send an invitation to a new Patient or a Clinic Technician.
          </p>
        </div>
        <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
          <.simple_form for={@form} phx-submit="invite_user">

            <.input
              field={@form[:invitee_email]}
              type="email"
              label="Email Address"
              required
            />

            <.input
              field={@form[:invitee_role]}
              type="select"
              label="Role to Invite"
              options={[
                {"Patient", "patient"},
                {"Clinic Technician", "clinic_technician"},
                {"Nurse", "nurse "},
                {"Doctor", "doctor"},
              ]}
              required
            />

            <:actions>
              <.button phx-disable-with="Sending Invitation...">Send Invitation</.button>
            </:actions>
          </.simple_form>
        </div>
      </div>
    </div>
    """
  end
end
