defmodule AnkaaWeb.CareNetworkInviteLive do
  use AnkaaWeb, :patient_layout

  alias Ankaa.Invites
  alias Ankaa.Accounts
  alias Ankaa.Invites.Invite

  @impl true
  def mount(_params, _session, socket) do
    changeset = Invite.changeset(%Invite{}, %{})

    {:ok,
     assign(socket,
       form: to_form(changeset),
       current_path: "/patient/carenetwork/invite"
     )}
  end

  @impl true
  def handle_event("invite", %{"invite" => invite_params}, socket) do
    current_user = socket.assigns.current_user
    invitee_email = invite_params["invitee_email"]
    invitee_role = invite_params["invitee_role"]
    patient_id = current_user.patient.id

    allowed_invites = %{
      "patient" => ["caresupport", "doctor", "nurse"],
      "doctor" => ["patient"],
      "nurse" => ["patient"],
      "caresupport" => []
    }

    existing_user = Accounts.get_user_by_email(invitee_email)

    inviter_role =
      if Accounts.User.is_patient?(current_user) do
        "patient"
      else
        current_user.role
      end

    allowed_roles_for_inviter = Map.get(allowed_invites, inviter_role, [])

    if invitee_role in allowed_roles_for_inviter do
      cond do
        current_user.email == invitee_email ->
          {:noreply,
           socket
           |> put_flash(:error, "You cannot invite yourself to your own care network.")}

        existing_user && existing_user.role != invitee_role ->
          {:noreply,
           socket
           |> put_flash(
             :error,
             "A user with email #{invitee_email} already exists with the role '#{existing_user.role}'. You cannot invite them as a '#{invitee_role}'."
           )}

        Invites.get_pending_invite_for_email_and_patient(invitee_email, patient_id) ->
          {:noreply,
           socket
           |> put_flash(
             :error,
             "An invitation has already been sent to #{invitee_email} and is still pending."
           )}

        true ->
          attrs = Map.put(invite_params, "patient_id", patient_id)

          case Invites.create_invite(current_user, attrs) do
            {:ok, _invite} ->
              {:noreply,
               socket
               |> put_flash(:info, "Invitation sent successfully to #{attrs["invitee_email"]}.")
               |> push_navigate(to: ~p"/patient/carenetwork")}

            {:error, %Ecto.Changeset{} = changeset} ->
              {:noreply, assign(socket, form: to_form(changeset))}

            {:error, {:error, _reason}} ->
              {:noreply,
               socket
               |> put_flash(:error, "Could not send invitation email. Please try again later.")}
          end
      end
    else
      {:noreply,
       put_flash(
         socket,
         :error,
         "A #{current_user.role} is not authorized to invite a #{invitee_role}."
       )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="max-w-3xl mx-auto">
        <div class="bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="px-4 py-5 sm:px-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900">Invite to Care Network</h3>
            <p class="mt-1 max-w-2xl text-sm text-gray-500">
              Invite someone to join your care network. They will receive an email invitation.
            </p>
          </div>
          <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
            <%!-- Use the CoreComponents .simple_form for automatic error handling --%>
            <.simple_form for={@form} phx-submit="invite">
              <.input
                field={@form[:invitee_email]}
                type="email"
                label="Email Address"
                placeholder="person@example.com"
                required
              />

              <.input
                field={@form[:invitee_role]}
                type="select"
                label="Role"
                options={[
                  "Care Support": "caresupport",
                  "Doctor": "doctor",
                  "Nurse": "nurse"
                ]}
                required
              />

              <:actions>
                <.link
                  navigate={~p"/patient/carenetwork"}
                  class="ml-auto px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
                >
                  Cancel
                </.link>
                <button
                  type="submit"
                  class="ml-3 inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
                  phx-disable-with="Sending..."
                >
                  Send Invitation
                </button>
              </:actions>
            </.simple_form>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
