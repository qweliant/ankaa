defmodule AnkaaWeb.PortalLive.Index do
  use AnkaaWeb, :live_view

  alias Ankaa.Patients
  alias Ankaa.Patients.Patient
  alias Ankaa.Communities

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    communities = Communities.list_organizations_for_user(user)
    my_patient_profile = Patients.get_patient_by_user_id(user.id)

    {:ok, care_networks} = Patients.list_patients_for_user(user)

    org_changeset = Communities.change_organization(%Ankaa.Community.Organization{})
    patient_changeset = Patient.changeset(%Patient{}, %{})

    {:ok,
     assign(socket,
       page_title: "My Portal",
       communities: communities,
       care_networks: care_networks,
       my_patient_profile: my_patient_profile,
       show_create_org_modal: false,
       show_create_patient_modal: false,
       org_form: to_form(org_changeset),
       patient_form: to_form(patient_changeset)
     )}
  end

  @impl true
  def handle_event("toggle_create_org", _params, socket) do
    {:noreply, assign(socket, show_create_org_modal: !socket.assigns.show_create_org_modal)}
  end

  @impl true
  def handle_event("toggle_create_patient", _params, socket) do
    {:noreply,
     assign(socket, show_create_patient_modal: !socket.assigns.show_create_patient_modal)}
  end

  @impl true
  def handle_event("create_community", %{"organization" => org_params}, socket) do
    user = socket.assigns.current_user

    case Communities.create_organization_with_defaults(user, org_params) do
      {:ok, %{org: _org}} ->
        updated_list = Communities.list_organizations_for_user(user)

        socket =
          socket
          |> put_flash(:info, "Community created successfully!")
          |> assign(communities: updated_list, show_create_org_modal: false)

        {:noreply, socket}

      {:error, failed_step, failed_value, _changes} ->
        {:noreply, handle_transaction_error(socket, failed_step, failed_value)}
    end
  end

  @impl true
  def handle_event("create_patient", %{"patient" => patient_params}, socket) do
    user = socket.assigns.current_user

    # This calls your new ReBAC logic in Ankaa.Patients
    case Patients.create_patient_hub(user, patient_params) do
      {:ok, %{patient: _patient}} ->
        {:ok, updated_networks} = Patients.list_patients_for_user(user)

        socket =
          socket
          |> put_flash(:info, "Care Network created successfully!")
          |> assign(care_networks: updated_networks, show_create_patient_modal: false)

        {:noreply, socket}

      {:error, failed_step, failed_value, _changes} ->
        {:noreply, handle_transaction_error(socket, failed_step, failed_value)}
    end
  end

  defp handle_transaction_error(socket, failed_step, failed_value) do
    error_msg =
      case failed_value do
        %Ecto.Changeset{} = changeset ->
          errors =
            Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
              Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
                opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
              end)
            end)

          "Validation failed at #{failed_step}: #{inspect(errors)}"

        _ ->
          "Failed at step: #{failed_step}"
      end

    put_flash(socket, :error, error_msg)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto py-10 px-4 sm:px-6 lg:px-8">
      <div class="mb-10 border-b border-gray-200 pb-6">
        <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:truncate sm:text-3xl">
          Welcome, {@current_user.first_name || @current_user.email}
        </h2>
        <p class="mt-1 text-sm text-gray-500">Select a workspace to get started.</p>
      </div>

      <div class="mb-12">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-sm font-semibold text-gray-500 uppercase tracking-wider">Care Networks</h3>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <%= if @my_patient_profile do %>
            <.link
              navigate={~p"/p/#{@my_patient_profile.id}/dashboard"}
              class="group relative flex flex-col justify-between rounded-2xl bg-white p-6 shadow-sm ring-1 ring-gray-900/5 transition hover:shadow-md hover:ring-gray-900/10"
            >
              <div>
                <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-red-50 group-hover:bg-red-100 transition-colors">
                  <.icon name="hero-heart" class="h-6 w-6 text-red-600" />
                </div>
                <h3 class="mt-4 font-semibold text-gray-900">My Health</h3>
                <p class="mt-1 text-sm text-gray-500">Track your vitals and sessions.</p>
              </div>
              <div class="mt-4 text-sm font-semibold text-red-600">
                Open Dashboard <span aria-hidden="true">&rarr;</span>
              </div>
            </.link>
          <% end %>

          <%= for patient <- @care_networks do %>
            <.link
              navigate={~p"/p/#{patient.id}/dashboard"}
              class="group relative flex flex-col justify-between rounded-2xl bg-white p-6 shadow-sm ring-1 ring-gray-900/5 transition hover:shadow-md hover:ring-gray-900/10"
            >
              <div>
                <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-blue-50 group-hover:bg-blue-100 transition-colors">
                  <.icon name="hero-user" class="h-6 w-6 text-blue-600" />
                </div>
                <h3 class="mt-4 font-semibold text-gray-900">{patient.name}</h3>
                <p class="mt-1 text-sm text-gray-500">Caregiver View</p>
              </div>
              <div class="mt-4 text-sm font-semibold text-blue-600">
                Open Dashboard <span aria-hidden="true">&rarr;</span>
              </div>
            </.link>
          <% end %>

          <button
            phx-click="toggle_create_patient"
            class="group relative flex h-full min-h-[180px] w-full flex-col items-center justify-center rounded-2xl border-2 border-dashed border-gray-300 bg-transparent p-6 text-center hover:border-blue-400 hover:bg-blue-50 transition-all focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
          >
            <div class="mx-auto flex h-10 w-10 items-center justify-center rounded-full bg-gray-50 group-hover:bg-blue-100 transition-colors">
              <.icon name="hero-user-plus" class="h-6 w-6 text-gray-400 group-hover:text-blue-600" />
            </div>
            <h3 class="mt-2 text-sm font-semibold text-gray-900">Create Care Network</h3>
            <p class="mt-1 text-sm text-gray-500">Set up a hub for a patient</p>
          </button>
        </div>
      </div>

      <div>
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-sm font-semibold text-gray-500 uppercase tracking-wider">My Communities</h3>
        </div>

        <ul role="list" class="grid grid-cols-1 gap-6 md:grid-cols-3">
          <%= for org <- @communities do %>
            <li class="col-span-1">
              <.link
                navigate={~p"/c/#{org.id}/dashboard"}
                class="group relative flex h-full flex-col justify-between rounded-2xl bg-white p-6 shadow-sm ring-1 ring-gray-900/5 transition hover:shadow-md hover:ring-gray-900/10"
              >
                <div>
                  <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-purple-50 group-hover:bg-purple-100 transition-colors">
                    <.icon name="hero-building-office-2" class="h-6 w-6 text-purple-600" />
                  </div>
                  <h3 class="mt-4 font-semibold text-gray-900 truncate">{org.name}</h3>
                  <p class="mt-1 text-sm text-gray-500 line-clamp-2">
                    {org.description || "Community Hub"}
                  </p>
                </div>
                <div class="mt-4 text-sm font-semibold text-purple-600">
                  Enter Hub <span aria-hidden="true">&rarr;</span>
                </div>
              </.link>
            </li>
          <% end %>

          <li class="col-span-1">
            <button
              phx-click="toggle_create_org"
              class="group relative flex h-full min-h-[180px] w-full flex-col items-center justify-center rounded-2xl border-2 border-dashed border-gray-300 bg-transparent p-6 text-center hover:border-purple-400 hover:bg-purple-50 transition-all focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-offset-2"
            >
              <div class="mx-auto flex h-10 w-10 items-center justify-center rounded-full bg-gray-50 group-hover:bg-purple-100 transition-colors">
                <.icon name="hero-plus" class="h-6 w-6 text-gray-400 group-hover:text-purple-600" />
              </div>
              <h3 class="mt-2 text-sm font-semibold text-gray-900">Create New Community</h3>
              <p class="mt-1 text-sm text-gray-500">Start a support group</p>
            </button>
          </li>
        </ul>
      </div>

      <div class="mt-20 border-t border-gray-100 pt-8">
        <div class="flex flex-col md:flex-row items-center justify-between gap-4 text-sm text-gray-500">
          <p>Safehemo Beta v0.1.0</p>
          <div class="flex items-center gap-6">
            <a
              href="https://forms.gle/b1mLmrXVJseidSdSA"
              target="_blank"
              class="hover:text-purple-600 transition-colors"
            >
              Submit Feedback
            </a>
            <a
              href="https://github.com/qweliant/ankaa/discussions"
              target="_blank"
              class="hover:text-purple-600 transition-colors"
            >
              Join Discussion
            </a>
            <a
              href="https://github.com/qweliant/ankaa/issues"
              target="_blank"
              class="hover:text-rose-600 transition-colors"
            >
              Report a Bug
            </a>
          </div>
        </div>
      </div>

      <%= if @show_create_org_modal do %>
        <div class="relative z-50" role="dialog" aria-modal="true">
          <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"></div>
          <div class="fixed inset-0 z-10 w-screen overflow-y-auto">
            <div class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
              <div class="relative transform overflow-hidden rounded-lg bg-white px-4 pb-4 pt-5 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg sm:p-6">
                <div class="absolute right-0 top-0 hidden pr-4 pt-4 sm:block">
                  <button
                    phx-click="toggle_create_org"
                    type="button"
                    class="rounded-md bg-white text-gray-400 hover:text-gray-500"
                  >
                    <span class="sr-only">Close</span>
                    <.icon name="hero-x-mark" class="h-6 w-6" />
                  </button>
                </div>
                <div class="sm:flex sm:items-start">
                  <div class="mx-auto flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-purple-100 sm:mx-0 sm:h-10 sm:w-10">
                    <.icon name="hero-building-library" class="h-6 w-6 text-purple-600" />
                  </div>
                  <div class="mt-3 text-center sm:ml-4 sm:mt-0 sm:text-left w-full">
                    <h3 class="text-base font-semibold leading-6 text-gray-900">
                      Create a Community
                    </h3>
                    <div class="mt-2">
                      <p class="text-sm text-gray-500 mb-4">
                        Start a new space for your clinic, neighborhood, or support group.
                      </p>
                      <.simple_form for={@org_form} phx-submit="create_community">
                        <.input
                          field={@org_form[:name]}
                          label="Community Name"
                          placeholder="e.g. Northside Dialysis Support"
                          required
                        />
                        <.input
                          field={@org_form[:description]}
                          type="textarea"
                          label="Description"
                          placeholder="A brief goal for this group..."
                        />
                        <:actions>
                          <.button class="w-full">Create Community</.button>
                        </:actions>
                      </.simple_form>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      <% end %>

      <%= if @show_create_patient_modal do %>
        <div class="relative z-50" role="dialog" aria-modal="true">
          <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"></div>
          <div class="fixed inset-0 z-10 w-screen overflow-y-auto">
            <div class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
              <div class="relative transform overflow-hidden rounded-lg bg-white px-4 pb-4 pt-5 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg sm:p-6">
                <div class="absolute right-0 top-0 hidden pr-4 pt-4 sm:block">
                  <button
                    phx-click="toggle_create_patient"
                    type="button"
                    class="rounded-md bg-white text-gray-400 hover:text-gray-500"
                  >
                    <span class="sr-only">Close</span>
                    <.icon name="hero-x-mark" class="h-6 w-6" />
                  </button>
                </div>

                <div class="sm:flex sm:items-start">
                  <div class="mx-auto flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-blue-100 sm:mx-0 sm:h-10 sm:w-10">
                    <.icon name="hero-heart" class="h-6 w-6 text-blue-600" />
                  </div>
                  <div class="mt-3 text-center sm:ml-4 sm:mt-0 sm:text-left w-full">
                    <h3 class="text-base font-semibold leading-6 text-gray-900">
                      Create Care Network
                    </h3>
                    <div class="mt-2">
                      <p class="text-sm text-gray-500 mb-4">
                        Set up a dashboard for yourself or a loved one.
                      </p>

                      <.simple_form for={@patient_form} phx-submit="create_patient">
                        <.input
                          field={@patient_form[:name]}
                          label="Patient Name"
                          placeholder="e.g. Mom, or your own name"
                          required
                        />

                        <:actions>
                          <.button class="w-full bg-blue-600 hover:bg-blue-700">
                            Create Dashboard
                          </.button>
                        </:actions>
                      </.simple_form>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
