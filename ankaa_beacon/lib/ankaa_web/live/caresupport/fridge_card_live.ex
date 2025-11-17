defmodule AnkaaWeb.FridgeCardComponent do
  @moduledoc """
  A LiveComponent that allows caregivers to view and edit emergency "fridge card" notes
  for a patient. These notes are private to the caregiver and can include important
  information such as clinic phone numbers, allergies, and medication lists.
  """
  use AnkaaWeb, :live_component

  alias Ankaa.Patients
  alias Ankaa.Patients.CareNetwork

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       form: nil,
       save_status: :idle
     )}
  end

  @impl true
  def update(assigns, socket) do
    entry = Map.get(assigns, :care_network_entry)

    changeset =
      if entry do
        CareNetwork.changeset(entry, %{})
      else
        CareNetwork.changeset(%CareNetwork{}, %{})
      end

    form = to_form(changeset, as: "notes")

    {:ok,
     assign(socket,
       form: form,
       care_network_entry: entry,
       patient: assigns.patient,
       current_user: assigns.current_user
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white shadow rounded-lg p-6">
      <h2 class="text-lg font-medium text-gray-900">Emergency "Fridge Card"</h2>
      <p class="mt-2 text-sm text-gray-600">
        These notes are private to you. Use this space for clinic phone numbers,
        allergies, or medication lists for quick access.
      </p>

      <.simple_form
        for={@form}
        phx-submit="save"
        phx-target={@myself}
        phx-trigger-action={@save_status == :saved}
        phx-action-name="saved"
        class="mt-4"
      >
        <.input
          type="textarea"
          field={@form[:fridge_card_notes]}
          label="Emergency Notes"
          placeholder="e.g., Clinic Phone: 555-1234, Allergies: Penicillin, Meds: ..."
          rows={10}
        />

        <:actions>
          <div class="flex items-center w-full">
            <.button type="submit" class="bg-blue-600 hover:bg-blue-700" phx-disable-with="Saving...">
              Save Notes
            </.button>

            <span
              class="ml-4 text-green-600 font-medium transition-opacity ease-in-out duration-300"
              phx-show={@save_status == :saved}
              phx-remove={JS.hide(transition: {"ease-in duration-300", "opacity-100", "opacity-0"})}
            >
              <.icon name="hero-check-circle" class="h-5 w-5 inline-block -mt-1" /> Saved!
            </span>
          </div>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("save", %{"notes" => %{"fridge_card_notes" => notes}}, socket) do
    patient = socket.assigns.patient
    user = socket.assigns.current_user

    case Patients.get_or_create_care_network_entry(user.id, patient.id) do
      {:ok, entry_to_update} ->
        case Patients.update_fridge_card_notes(entry_to_update, notes) do
          {:ok, updated_entry} ->
            form = CareNetwork.changeset(updated_entry, %{}) |> to_form(as: "notes")

            {:noreply,
             assign(socket,
               form: form,
               care_network_entry: updated_entry,
               save_status: :saved
             )}

          {:error, changeset} ->
            {:noreply, assign(socket, form: to_form(changeset, as: "notes"))}
        end

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "notes"))}
    end
  end

  @impl true
  def handle_event("saved", _, socket) do
    {:noreply, assign(socket, save_status: :idle)}
  end
end
