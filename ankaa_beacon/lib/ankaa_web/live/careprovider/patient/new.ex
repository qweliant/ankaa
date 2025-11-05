defmodule AnkaaWeb.CareProvider.PatientLive.New do
  use AnkaaWeb, :live_view

  alias Ankaa.Invites
  alias Ankaa.Accounts

  @impl true
  def mount(_params, _session, socket) do
    changeset = Invites.Invite.changeset(%Invites.Invite{}, %{})
    {:ok, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("invite_patient", %{"invite" => invite_params}, socket) do
    current_user = socket.assigns.current_user
    invitee_email = invite_params["invitee_email"]
    existing_user = Accounts.get_user_by_email(invitee_email)

    attrs = %{
      "invitee_email" => invitee_email,
      "invitee_role" => "patient",
      "patient_id" => nil
    }

   cond do
      existing_user && Accounts.User.patient?(existing_user) ->
        {:noreply,
         put_flash(socket, :error, "A user with this email is already registered as a patient.")}
      # in the future we will allow care support to be invited as patients. we just dont have any way to handle multiple roles
      existing_user && existing_user.role != nil ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "A user with this email is already registered under another role."
         )}

      true ->
        case Invites.create_invite(current_user, attrs) do
          {:ok, _invite} ->
            {:noreply,
             socket
             |> put_flash(:info, "Invitation sent successfully to #{invitee_email}.")
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
            Add New Patient
          </h3>
          <p class="mt-1 max-w-2xl text-sm text-gray-500">
            Enter the email address of the new patient you would like to invite to the platform.
          </p>
        </div>
        <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
          <.simple_form for={@form} phx-submit="invite_patient">
            <.input
              field={@form[:invitee_email]}
              type="email"
              label="New Patient's Email Address"
              required
            />
            <:actions>
              <.button phx-disable-with="Sending Invitation...">Add and Invite Patient</.button>
            </:actions>
          </.simple_form>
        </div>
      </div>
    </div>
    """
  end
end
