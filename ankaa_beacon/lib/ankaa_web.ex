defmodule AnkaaWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use AnkaaWeb, :controller
      use AnkaaWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: AnkaaWeb.Layouts]

      use Gettext, backend: AnkaaWeb.Gettext

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {AnkaaWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  def patient_layout do
    quote do
      use Phoenix.LiveView,
        layout: {AnkaaWeb.Layouts, :patient}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # Translation
      use Gettext, backend: AnkaaWeb.Gettext

      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components
      import AnkaaWeb.CoreComponents

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: AnkaaWeb.Endpoint,
        router: AnkaaWeb.Router,
        statics: AnkaaWeb.static_paths()
    end
  end

  def alert_handling do
    quote do
      # This injects the alert-handling logic into any LiveView that uses it.

      # Handle new alert broadcasts
      @impl true
      def handle_info({:new_alert, alert}, socket) do
        {:noreply, update(socket, :active_alerts, fn alerts -> [alert | alerts] end)}
      end

      # Handle alert dismissals
      @impl true
      def handle_info({:alert_dismissed, alert_id}, socket) do
        {:noreply,
         update(socket, :active_alerts, fn alerts ->
           Enum.reject(alerts, &(&1.id == alert_id))
         end)}
      end

      # Handle alert updates (like acknowledgments)
      @impl true
      def handle_info({:alert_updated, updated_alert}, socket) do
        updated_alerts =
          Enum.map(socket.assigns.active_alerts, fn alert ->
            if alert.id == updated_alert.id, do: updated_alert, else: alert
          end)

        {:noreply, assign(socket, active_alerts: updated_alerts)}
      end

      # Handle EMS escalations
      def handle_info({:ems_escalation, alert_id}, socket) do
        {:noreply,
         update(socket, :active_alerts, fn alerts ->
           Enum.map(alerts, fn alert ->
             if alert.id == alert_id do
               %{alert | ems_contacted: true, ems_contact_time: DateTime.utc_now()}
             else
               alert
             end
           end)
         end)}
      end
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
