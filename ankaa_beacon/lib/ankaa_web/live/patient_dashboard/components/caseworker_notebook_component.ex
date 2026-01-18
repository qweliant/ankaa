defmodule AnkaaWeb.PatientDashboard.Components.CaseworkerNotebookComponent do
  @moduledoc """
  A component that serves as a digital notebook for caseworkers, allowing them to log notes,
  track social determinants of health, and maintain a history of interactions and interventions.
  """
  use AnkaaWeb, :live_component
  alias Ankaa.Patients

  @impl true
  def update(%{patient: patient} = assigns, socket) do
    social_status = Patients.get_social_status(patient)

    kdqol_scores = %{
      # PCS (Below 50 is poor)
      physical: 34,
      # MCS
      mental: 48,
      # Burden of Kidney Disease (Low score = High Burden)
      burden: 22,
      date: "2026-01-10"
    }

    insurance = %{
      # Often commercial is Primary for the first 30 months of dialysis
      primary: "UnitedHealthcare (Choice Plus)",
      primary_id: "UHC-89320482",

      # Medicare becomes Secondary during the coordination period
      secondary: "Medicare Part A & B",
      secondary_id: "MBI-1EG4-TE5-MK72",

      # The status of the 2728 form is still critical for when Medicare eventually takes over
      cms_2728_status: "Submitted (2025-11-15)"
    }

    logistics = %{
      # Common transport broker
      transport: "ModivCare (Standing Order)",
      schedule: "MWF / 10:00 AM Chair",
      transplant_status: "Inactive (Pending Cardiac Clearance)"
    }

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       kdqol: kdqol_scores,
       insurance: insurance,
       logistics: logistics,
       social_status: social_status,
       note_form: to_form(%{"content" => ""}),
       case_notes: [
         %{
           id: 1,
           author: "Social Worker",
           date: DateTime.utc_now() |> DateTime.add(-2, :day),
           content:
             "Spoke with patient regarding transportation. She confirmed the car is still broken. Referred to RideShare Health."
         },
         %{
           id: 2,
           author: "Clinic Manager",
           date: DateTime.utc_now() |> DateTime.add(-10, :day),
           content: "Patient missed session due to 'lack of ride'. Flagging for SW intervention."
         }
       ]
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto pb-12 font-sans text-stone-800">
      <div class="bg-white border-b border-stone-200 pb-6 mb-8 flex flex-col md:flex-row md:items-start md:justify-between gap-4">
        <div>
          <h2 class="text-3xl font-serif font-bold text-stone-900 tracking-tight">
            Case File: {@patient.name}
          </h2>
          <div class="flex items-center gap-3 mt-2 text-sm text-stone-500">
            <span class="flex items-center">
              <.icon name="hero-identification" class="w-4 h-4 mr-1" />
              ID: {@patient.id |> String.slice(0, 8)}
            </span>
            <span>•</span>
            <span>DOB: {@patient.date_of_birth}</span>
            <span>•</span>
            <span class="text-stone-700 font-medium">{@logistics.schedule}</span>
          </div>
        </div>

        <div class="flex flex-col items-end">
          <div class="text-xs font-bold text-stone-400 uppercase tracking-wider mb-1">
            CMS-2728 Status
          </div>
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
            <.icon name="hero-check" class="w-3 h-3 mr-1" />
            {@insurance.cms_2728_status}
          </span>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-12 gap-8">
        <div class="lg:col-span-4 space-y-6">
          <div class="bg-white border border-stone-200 shadow-sm rounded-xl overflow-hidden">
            <div class="bg-stone-50 px-4 py-3 border-b border-stone-100 flex justify-between items-center">
              <h3 class="text-sm font-bold text-stone-700">KDQOL-36 Scores</h3>
              <span class="text-xs text-stone-400">{@kdqol.date}</span>
            </div>
            <div class="p-4 space-y-4">
              <div>
                <div class="flex justify-between text-xs mb-1">
                  <span class="font-medium">Physical Health (PCS)</span>
                  <span class={score_color(@kdqol.physical)}>{@kdqol.physical}/100</span>
                </div>
                <div class="w-full bg-stone-100 rounded-full h-1.5">
                  <div
                    class={"h-1.5 rounded-full #{bar_color(@kdqol.physical)}"}
                    style={"width: #{@kdqol.physical}%"}
                  >
                  </div>
                </div>
              </div>

              <div>
                <div class="flex justify-between text-xs mb-1">
                  <span class="font-medium">Mental Health (MCS)</span>
                  <span class={score_color(@kdqol.mental)}>{@kdqol.mental}/100</span>
                </div>
                <div class="w-full bg-stone-100 rounded-full h-1.5">
                  <div
                    class={"h-1.5 rounded-full #{bar_color(@kdqol.mental)}"}
                    style={"width: #{@kdqol.mental}%"}
                  >
                  </div>
                </div>
              </div>

              <div>
                <div class="flex justify-between text-xs mb-1">
                  <span class="font-medium">Burden of Disease</span>
                  <span class={score_color(@kdqol.burden)}>{@kdqol.burden}/100</span>
                </div>
                <div class="w-full bg-stone-100 rounded-full h-1.5">
                  <div
                    class={"h-1.5 rounded-full #{bar_color(@kdqol.burden)}"}
                    style={"width: #{@kdqol.burden}%"}
                  >
                  </div>
                </div>
                <p class="text-[10px] text-stone-400 mt-1 italic">
                  *Lower scores indicate higher burden/worse outcome.
                </p>
              </div>
            </div>
          </div>

          <div class="bg-[#FDFBF7] border border-stone-200 shadow-sm rounded-xl p-5">
            <h3 class="text-sm font-bold text-stone-700 mb-4 uppercase tracking-wider">
              Access & Logistics
            </h3>

            <dl class="space-y-4 text-sm">
              <div>
                <dt class="text-xs text-stone-400">Transportation</dt>
                <dd class="font-medium text-stone-900 flex items-center mt-0.5">
                  <.icon name="hero-truck" class="w-4 h-4 mr-1.5 text-stone-400" />
                  {@logistics.transport}
                </dd>
              </div>

              <div class="pt-3 border-t border-stone-100">
                <dt class="text-xs text-stone-400">Insurance Coverage</dt>

                <dd class="font-medium text-stone-900 mt-1 flex items-center justify-between">
                  <span class="flex items-center">
                    <.icon name="hero-shield-check" class="w-4 h-4 mr-1 text-blue-600" />
                    1. {@insurance.primary}
                  </span>
                  <span class="text-[10px] text-stone-400 bg-stone-100 px-1.5 rounded">Primary</span>
                </dd>
                <dd class="text-xs text-stone-400 pl-5 mb-2">ID: {@insurance.primary_id}</dd>

                <dd class="font-medium text-stone-900 mt-1 flex items-center justify-between">
                  <span class="flex items-center">
                    <.icon name="hero-shield-check" class="w-4 h-4 mr-1 text-blue-900" />
                    2. {@insurance.secondary}
                  </span>
                  <span class="text-[10px] text-stone-400 bg-stone-100 px-1.5 rounded">
                    Secondary
                  </span>
                </dd>
                <dd class="text-xs text-stone-400 pl-5">ID: {@insurance.secondary_id}</dd>
              </div>

              <div class="pt-3 border-t border-stone-100">
                <dt class="text-xs text-stone-400">Transplant Status</dt>
                <dd class="font-medium text-amber-700 bg-amber-50 inline-block px-2 py-1 rounded text-xs mt-1 border border-amber-100">
                  {@logistics.transplant_status}
                </dd>
              </div>
            </dl>
          </div>
        </div>

        <div class="lg:col-span-8">
          <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 mb-6">
            <button class="flex flex-col items-center justify-center p-3 bg-white border border-stone-200 rounded-lg shadow-sm hover:bg-stone-50 transition">
              <.icon name="hero-document-text" class="w-5 h-5 text-purple-600 mb-1" />
              <span class="text-xs font-medium text-stone-700">New Assessment</span>
            </button>
            <button class="flex flex-col items-center justify-center p-3 bg-white border border-stone-200 rounded-lg shadow-sm hover:bg-stone-50 transition">
              <.icon name="hero-truck" class="w-5 h-5 text-blue-600 mb-1" />
              <span class="text-xs font-medium text-stone-700">Transport Req</span>
            </button>
            <button class="flex flex-col items-center justify-center p-3 bg-white border border-stone-200 rounded-lg shadow-sm hover:bg-stone-50 transition">
              <.icon name="hero-heart" class="w-5 h-5 text-red-600 mb-1" />
              <span class="text-xs font-medium text-stone-700">Transplant Ref</span>
            </button>
            <button class="flex flex-col items-center justify-center p-3 bg-white border border-stone-200 rounded-lg shadow-sm hover:bg-stone-50 transition">
              <.icon name="hero-phone" class="w-5 h-5 text-green-600 mb-1" />
              <span class="text-xs font-medium text-stone-700">Call Patient</span>
            </button>
          </div>

          <div class="bg-white shadow-sm border border-stone-200 rounded-xl p-1 mb-8">
            <.simple_form for={@note_form} phx-submit="save_note" phx-target={@myself}>
              <textarea
                name="content"
                rows="2"
                class="block w-full border-0 p-4 text-stone-900 placeholder:text-stone-400 focus:ring-0 sm:text-sm resize-none rounded-t-xl"
                placeholder="Log a contact, barrier, or intervention..."
              ></textarea>
              <div class="flex items-center justify-between border-t border-stone-100 bg-stone-50 px-3 py-2 rounded-b-xl">
                <div class="flex gap-2">
                  <span class="inline-flex items-center rounded-md bg-stone-100 px-2 py-1 text-xs font-medium text-stone-600 ring-1 ring-inset ring-stone-500/10 cursor-pointer hover:bg-stone-200">
                    Topic: Transport
                  </span>
                  <span class="inline-flex items-center rounded-md bg-stone-100 px-2 py-1 text-xs font-medium text-stone-600 ring-1 ring-inset ring-stone-500/10 cursor-pointer hover:bg-stone-200">
                    Topic: Insurance
                  </span>
                </div>
                <button
                  type="submit"
                  class="bg-stone-800 text-white px-3 py-1.5 rounded-md text-sm font-medium hover:bg-stone-700"
                >
                  Log Note
                </button>
              </div>
            </.simple_form>
          </div>

          <div class="space-y-6">
            <h3 class="text-xs font-bold text-stone-400 uppercase tracking-wider border-b border-stone-200 pb-2">
              History
            </h3>
            <%= for note <- @case_notes do %>
              <div class="flex gap-4 group">
                <div class="flex flex-col items-center pt-1">
                  <div class="w-2 h-2 rounded-full bg-stone-300 group-hover:bg-purple-500 transition-colors">
                  </div>
                  <div class="w-px h-full bg-stone-200 my-1"></div>
                </div>
                <div class="pb-4 flex-1">
                  <div class="flex items-center justify-between mb-1">
                    <span class="text-sm font-bold text-stone-900">{note.author}</span>
                    <span class="text-xs text-stone-500">
                      {Calendar.strftime(note.date, "%b %d • %-I:%M %p")}
                    </span>
                  </div>
                  <p class="text-stone-700 text-sm leading-relaxed font-serif">
                    {note.content}
                  </p>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp score_color(score) when score < 40, do: "text-red-600 font-bold"
  defp score_color(score) when score < 60, do: "text-yellow-600 font-bold"
  defp score_color(_), do: "text-green-600 font-bold"

  defp bar_color(score) when score < 40, do: "bg-red-500"
  defp bar_color(score) when score < 60, do: "bg-yellow-500"
  defp bar_color(_), do: "bg-green-500"

  @impl true
  def handle_event("save_note", %{"content" => content}, socket) do
    new_note = %{
      id: System.unique_integer([:positive]),
      author: "You",
      date: DateTime.utc_now(),
      content: content
    }

    {:noreply, update(socket, :case_notes, fn notes -> [new_note | notes] end)}
  end
end
