defmodule AnkaaWeb.PatientNav do
  @moduledoc """
  Patient navigation bar component.
  """
  use AnkaaWeb, :live_component

  def render(assigns) do
    ~H"""
    <nav class="bg-white shadow-sm">
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div class="flex h-16 justify-between">
          <div class="flex">
            <div class="flex space-x-8">
            <.link
                navigate={~p"/patient/monitoring"}
                class={[
                  "inline-flex items-center border-b-2 px-1 pt-1 text-sm font-medium",
                  if(@current_path == "/patient/monitoring",
                    do: "border-indigo-500 text-gray-900",
                    else: "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700"
                  )
                ]}
              >
                Session Monitoring
              </.link>
              <.link
                navigate={~p"/patient/health"}
                class={[
                  "inline-flex items-center border-b-2 px-1 pt-1 text-sm font-medium",
                  if(@current_path == "/patient/health",
                    do: "border-indigo-500 text-gray-900",
                    else: "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700"
                  )
                ]}
              >
                Health
              </.link>
              <.link
                navigate={~p"/patient/carenetwork"}
                class={[
                  "inline-flex items-center border-b-2 px-1 pt-1 text-sm font-medium",
                  if(@current_path == "/patient/carenetwork",
                    do: "border-indigo-500 text-gray-900",
                    else: "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700"
                  )
                ]}
              >
                Care Network
              </.link>
              <.link
                navigate={~p"/patient/devices"}
                class={[
                  "inline-flex items-center border-b-2 px-1 pt-1 text-sm font-medium",
                  if(@current_path == "/patient/devices",
                    do: "border-indigo-500 text-gray-900",
                    else: "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700"
                  )
                ]}
              >
                My Devices
              </.link>
              <.link
                navigate={~p"/patient/inbox"}
                class={[
                  "inline-flex items-center border-b-2 px-1 pt-1 text-sm font-medium",
                  if(@current_path == "/patient/inbox",
                    do: "border-indigo-500 text-gray-900",
                    else: "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700"
                  )
                ]}
              >
                My Inbox
              </.link>
            </div>
          </div>
        </div>
      </div>
    </nav>
    """
  end
end
