defmodule AnkaaWeb.DailyTrackerComponent do
  @moduledoc """
  LiveComponent for tracking and displaying patient's daily mood entries.
  It renders a form or a completion message based on if an entry exists for today.
  """
  use AnkaaWeb, :live_component

  # Alias the necessary contexts/schemas
  alias Ankaa.Patients
  alias Ankaa.Patients.MoodTracker

  @mood_emojis [
    %{value: "Great", label: "Great", emoji: "🤩"},
    %{value: "Good", label: "Good", emoji: "😊"},
    %{value: "Okay", label: "Okay", emoji: "😐"},
    %{value: "Fatigued", label: "Fatigued", emoji: "🫩"},
    %{value: "Poor", label: "Poor", emoji: "😞"}
  ]
  @mood_options ["Good", "Okay", "Fatigued", "Great", "Poor"]
  @available_symptoms [
    "Cramps",
    "Itchy",
    "Nausea",
    "Headache",
    "Fever",
    "Felt Cold",
    "Shortness of Breath"
  ]

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       entry: nil,
       form: nil,
       mood_options: @mood_options,
       available_symptoms: @available_symptoms,
       mood_emojis: @mood_emojis
     )}
  end

  @impl true
  def update(assigns, socket) do
    # Update runs after mount and receives all parent assigns then we copy the data needed for the component's state
    entry = assigns.entry

    changeset =
      if entry do
        # If entry exists, use it to pre-fill for editing
        Patients.get_mood_tracker_changeset(entry)
      else
        # Otherwise, prepare a new changeset
        Patients.create_mood_tracker_changeset(assigns.current_user.patient)
      end

    form = to_form(changeset, as: "mood_tracker")

    {:ok,
     assign(socket,
       entry: entry,
       form: form,
       patient: assigns.current_user.patient,
       current_user: assigns.current_user
     )}
  end

  @impl true
  def handle_event("save_mood", %{"mood_tracker" => params}, socket) do
    patient = socket.assigns.patient

    case Patients.save_mood_tracker_entry(patient, params) do
      {:ok, entry} ->
        # Send a message to the parent (HealthLive) to refresh its state
        send(self(), {:mood_updated, entry})
        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("edit_mood", _params, socket) do
    # Use the existing entry to pre-fill the form
    entry = socket.assigns.entry

    form =
      entry
      |> MoodTracker.changeset(%{})
      |> to_form()

    {:noreply, assign(socket, entry: nil, form: form)}
  end

  @impl true
  def handle_event("validate_mood", %{"mood_tracker" => params}, socket) do
    # If @entry exists, use it to start the changeset; otherwise, use the current form's data struct
    changeset =
      (socket.assigns.entry || socket.assigns.form.source)
      |> Ankaa.Patients.MoodTracker.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("select_mood", %{"mood" => mood_value}, socket) do
    # Create a new map to update the form's data with the selected mood
    params = %{"mood" => mood_value}

    changeset =
      socket.assigns.form.source
      |> Ankaa.Patients.MoodTracker.changeset(params)
      |> Map.put(:action, :validate)

    # update the form don't re-render the whole LiveView
    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white shadow rounded-lg p-6 mb-8 border border-slate-200">
      <h2 class="text-xl font-semibold text-slate-800 mb-4">Daily Well-being Check</h2>

      <%= if @entry do %>
        <% # --- SUCCESS MESSAGE VIEW (Improved) --- %>
        <div class="flex items-center justify-between p-4 bg-green-50 rounded-lg">
          <div class="flex items-center">
            <.icon name="hero-check-circle" class="h-6 w-6 text-green-500 mr-3" />
            <div>
              <p class="text-sm font-medium text-green-700">Check-in Complete for Today!</p>
              <p class="text-sm text-green-600">Your mood was logged as: **{@entry.mood}**.</p>
              <%= if @entry.symptoms do %>
                <p class="text-xs text-green-600/80 mt-1">
                  Symptoms: {Enum.join(@entry.symptoms, ", ")}
                </p>
              <% end %>
            </div>
          </div>
          <button
            phx-click="edit_mood"
            phx-target={@myself}
            class="text-sm font-medium text-indigo-600 hover:text-indigo-800"
          >
            Edit
          </button>
        </div>
      <% else %>
        <div class="space-y-6">
          <h3 class="text-lg font-medium text-slate-700">1. How do you feel today?</h3>

          <% # --- NEW: EMOJI SELECTION GRID --- %>
          <div class="flex gap-4 justify-between p-2 rounded-lg bg-gray-50 border border-gray-200">
            <%= for mood_option <- @mood_emojis do %>
              <div class="flex flex-col items-center group cursor-pointer">
                <button
                  phx-click="select_mood"
                  phx-value-mood={mood_option.value}
                  phx-target={@myself}
                  type="button"
                  class={"p-3 rounded-full text-4xl transition-all shadow-md
                          #{if @form[:mood].value == mood_option.value, do: "bg-indigo-50 ring-2 ring-indigo-500 scale-110", else: "bg-white hover:bg-gray-100"}"}
                  title={mood_option.label}
                >
                  {mood_option.emoji}
                </button>
                <span class={"mt-1 text-xs font-medium #{if @form[:mood].value == mood_option.value, do: "text-indigo-600", else: "text-gray-500"}"}>
                  {mood_option.label}
                </span>
              </div>
            <% end %>
          </div>
          <% # --- END EMOJI SELECTION GRID --- %>

          <h3 class="text-lg font-medium text-slate-700 pt-4">2. Symptom Tags (Optional)</h3>

          <% # Use the form context to tie the inputs together %>
          <.simple_form
            for={@form}
            id="mood-tracker-form"
            phx-submit="save_mood"
            phx-change="validate_mood"
            phx-target={@myself}
          >
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <.checkgroup
                field={@form[:symptoms]}
                label="Select all that apply"
                options={Enum.map(@available_symptoms, &{&1, &1})}
              />
            </div>

            <.input
              field={@form[:notes]}
              type="textarea"
              label="Additional Notes"
              rows="3"
              placeholder="e.g., Slept well, but feeling slightly itchy."
            />

            <:actions>
              <.button phx-disable-with="Saving..." class="bg-indigo-600 hover:bg-indigo-700">
                Save Check-in
              </.button>
            </:actions>
          </.simple_form>
        </div>
      <% end %>
    </div>
    """
  end
end
