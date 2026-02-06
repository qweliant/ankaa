defmodule AnkaaWeb.Router do
  use AnkaaWeb, :router

  import AnkaaWeb.UserAuth

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {AnkaaWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:fetch_current_user)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  # Public routes
  scope "/", AnkaaWeb do
    pipe_through(:browser)

    get("/", PageController, :home)
    get("/learn-more", PageController, :learn_more)
    live("/privacy-policy", StaticPageLive, :privacy)
    live("/disclaimer", StaticPageLive, :disclaimer)
    live("/cookie-policy", StaticPageLive, :cookies)
  end

  # Other scopes may use custom stacks.
  # scope "/api", AnkaaWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ankaa, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: AnkaaWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end

  ## Authentication routes
  scope "/", AnkaaWeb do
    pipe_through([:browser, :redirect_if_user_is_authenticated])

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{AnkaaWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live("/users/register", UserRegistrationLive, :new)
      live("/users/login", UserLoginLive, :new)
      live("/users/reset_password", UserForgotPasswordLive, :new)
      live("/users/reset_password/:token", UserResetPasswordLive, :edit)
    end

    post("/users/login", UserSessionController, :create)
  end

  # Authenticated routes
  scope "/", AnkaaWeb do
    pipe_through([:browser, :require_authenticated_user])

    live_session :authenticated,
      on_mount: [
        {AnkaaWeb.UserAuth, :ensure_authenticated},
        {AnkaaWeb.AlertHook, :subscribe_alerts}
      ] do
      # live("/register", RoleRegistrationLive, :new)
      live("/portal", PortalLive.Index, :index)
      live("/users/settings", UserSettingsLive, :edit)
      live("/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email)
    end
  end

  scope "/", AnkaaWeb do
    pipe_through([:browser])

    delete("/users/logout", UserSessionController, :delete)
    get("/users/log_in_from_token", UserSessionController, :log_in_from_token)

    live_session :current_user,
      on_mount: [{AnkaaWeb.UserAuth, :mount_current_user}] do
      live("/invites/accept", AcceptInviteLive, :new)
      live("/users/confirm/:token", UserConfirmationLive, :edit)
      live("/users/confirm", UserConfirmationInstructionsLive, :new)
    end
  end

  scope "/p/:patient_id", AnkaaWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :patient_context,
      on_mount: [
        {AnkaaWeb.UserAuth, :ensure_authenticated},
        {AnkaaWeb.AlertHook, :subscribe_alerts}
      ] do
      live "/dashboard", PatientDashboardLive, :index
    end
  end

  scope "/c/:community_id", AnkaaWeb do
    pipe_through([:browser, :require_authenticated_user])

    live_session :community_db,
      on_mount: [
        {AnkaaWeb.UserAuth, :ensure_authenticated},
        {AnkaaWeb.RoleAuth, :require_community_access}
      ] do
      live("/dashboard", CommunityDashboardLive, :index)
    end
  end
end
