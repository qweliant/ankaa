defmodule AnkaaWeb.Community.Components.ResourcesComponent do
  @moduledoc """
  This component manages the Resource Library for a community. It allows moderators to add and remove resources
  (links, documents, etc.) that are relevant to the community. Regular members can view and access these resources
  but cannot modify them. The component handles the display of resources, the form for adding new
  resources, and the deletion of existing resources.
  """
  use AnkaaWeb, :live_component

  alias Ankaa.Communities
  alias Ankaa.Community.Resource

  @impl true
  def update(assigns, socket) do
    is_mod = Communities.moderator?(assigns.current_role)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       is_mod: is_mod,
       resources: Communities.list_resources(assigns.org.id),
       form: to_form(Communities.change_resource(%Resource{})),
       show_form: false
     )}
  end

  @impl true
  def handle_event("toggle_form", _, socket) do
    {:noreply, assign(socket, show_form: !socket.assigns.show_form)}
  end

  @impl true
  def handle_event("save_resource", %{"resource" => params}, socket) do
    if socket.assigns.is_mod == false do
      {:noreply, put_flash(socket, :error, "Unauthorized")}
    else
      params = Map.put(params, "organization_id", socket.assigns.org.id)

      case Communities.create_resource(params) do
        {:ok, _} ->
          updated_resources = Communities.list_resources(socket.assigns.org.id)

          {:noreply,
           socket
           |> assign(show_form: false, resources: updated_resources)
           |> put_flash(:info, "Resource added to library.")}

        {:error, changeset} ->
          {:noreply, assign(socket, form: to_form(changeset))}
      end
    end
  end

  @impl true
  def handle_event("delete_resource", %{"id" => id}, socket) do
    if !socket.assigns.is_mod do
      {:noreply, put_flash(socket, :error, "Unauthorized")}
    else
      resource = Communities.get_resource!(id)
      {:ok, _} = Communities.delete_resource(resource)

      updated_resources = Communities.list_resources(socket.assigns.org.id)
      {:noreply, socket |> assign(resources: updated_resources) |> put_flash(:info, "Resource deleted.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto space-y-6 animate-fade-in-up">

      <div class="flex items-center justify-between">
        <h3 class="text-lg font-semibold text-gray-900 flex items-center">
          <.icon name="hero-book-open" class="w-5 h-5 mr-2 text-teal-600" /> Resource Library
        </h3>

        <%= if @is_mod do %>
          <button
            phx-click="toggle_form"
            phx-target={@myself}
            class="text-sm text-teal-600 hover:text-teal-900 font-medium"
          >
            {if @show_form, do: "Cancel", else: "+ Add Link"}
          </button>
        <% end %>
      </div>

      <%= if @show_form do %>
        <div class="bg-gray-50 p-4 rounded-lg border border-gray-200 shadow-inner">
          <.simple_form for={@form} phx-submit="save_resource" phx-target={@myself}>
            <.input field={@form[:title]} label="Title" placeholder="e.g. Diet Guide" required />
            <.input field={@form[:url]} label="URL" placeholder="https://..." required />

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <.input field={@form[:category]} type="select" label="Category" options={["Diet", "Lifestyle", "Technical", "Financial"]} required />
              <.input field={@form[:description]} type="textarea" label="Description" rows="1" />
            </div>

            <:actions>
              <.button class="w-full bg-teal-600 hover:bg-teal-700">Save Resource</.button>
            </:actions>
          </.simple_form>
        </div>
      <% end %>

      <div class="space-y-4">
        <%= for resource <- @resources do %>
          <div class="relative group">
            <a href={resource.url} target="_blank" class="block bg-white shadow rounded-lg p-4 hover:ring-1 hover:ring-teal-500 transition-all">
               <div class="flex justify-between items-start">
                 <h4 class="font-bold text-teal-700 group-hover:underline">
                   {resource.title} ↗
                 </h4>
                 <span class="inline-flex mt-1 items-center rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-600">
                    {resource.category}
                 </span>
               </div>
               <p class="text-sm text-gray-600 mt-2">{resource.description}</p>
            </a>

            <%= if @is_mod do %>
              <button
                phx-click="delete_resource"
                phx-value-id={resource.id}
                phx-target={@myself}
                data-confirm="Delete this resource?"
                class="absolute top-2 right-2 p-1 bg-white rounded-full text-gray-300 hover:text-red-500 hover:bg-red-50 opacity-0 group-hover:opacity-100 transition-opacity"
              >
                <.icon name="hero-trash" class="w-4 h-4" />
              </button>
            <% end %>
          </div>
        <% end %>

        <%= if Enum.empty?(@resources) do %>
           <div class="text-center py-8 bg-gray-50 rounded-lg border-2 border-dashed border-gray-200">
             <p class="text-sm text-gray-400">Library is empty.</p>
           </div>
        <% end %>
      </div>

    </div>
    """
  end
end
