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
      on_mount: [{AnkaaWeb.UserAuth, :ensure_authenticated}] do
      # Role and patient registration routes
      live("/register", RoleRegistrationLive, :new)

      # User settings
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

  # Patient routes
  scope "/patient", AnkaaWeb do
    pipe_through([:browser, :require_authenticated_user])

    live_session :patient,
      on_mount: [
        {AnkaaWeb.UserAuth, :ensure_authenticated},
        {AnkaaWeb.RoleAuth, :require_patient},
        {AnkaaWeb.AlertHook, :subscribe_alerts}
      ] do
      live("/health", HealthLive, :index)
      live("/monitoring", MonitoringLive, :index)
      live("/devices/new", DeviceEntryLive, :new)
      live("/devices", DeviceLive, :index)
      live("/devices/:id/edit", DeviceLive, :edit)
      live("/carenetwork/invite", CareNetworkInviteLive, :new)
      live("/carenetwork/", CareNetworkLive, :index)
    end
  end

  # Doctor + Nurse routes
  scope "/careprovider", AnkaaWeb do
    pipe_through([:browser, :require_authenticated_user])

    live_session :care_provider,
      on_mount: [
        {AnkaaWeb.UserAuth, :ensure_authenticated},
        {AnkaaWeb.RoleAuth, :require_doctor_or_nurse},
        {AnkaaWeb.AlertHook, :subscribe_alerts}
      ] do
      live("/patients", CareProvider.PatientsLive.Index, :index)
      live("/patient/new", CareProvider.PatientLive.New, :new)
      live("/patient/:id", CareProvider.PatientDetailsLive.Index, :index)
      live("/patient/:id/edit", CareProvider.PatientLive.Edit, :edit)
    end
  end

  # Care support routes
  scope "/caresupport", AnkaaWeb do
    pipe_through([:browser, :require_authenticated_user])

    live_session :caresupport,
      on_mount: [
        {AnkaaWeb.UserAuth, :ensure_authenticated},
        {AnkaaWeb.RoleAuth, :require_caresupport},
        {AnkaaWeb.AlertHook, :subscribe_alerts}
      ] do
      live("/caringfor", CaringForLive.Index, :index)
      live("/caringfor/:id", CaringForLive.Show, :show)
    end
  end

  # # Technical Support routes
  # scope "/support", AnkaaWeb do
  #   pipe_through([:browser, :require_authenticated_user])

  #   live_session :technical_support,
  #     on_mount: [{AnkaaWeb.UserAuth, :ensure_authenticated},{AnkaaWeb.RoleAuth, :require_technical_support}] do
  #     live("/home", SupportDashboardLive.Index, :index)
  #     live("/devices", DeviceSupportLive.Index, :index)
  #     live("/device/:id", DeviceSupportLive.Show, :show)
  #     live("/device/tickets", DeviceSupportLive.Tickets, :index)
  #     live("/device/ticket/:id", DeviceSupportLive.Show, :show)
  #     live("/alerts", AlertSupportLive.Index, :index)
  #     live("/alert/:id", AlertSupportLive.Show, :show)
  #     live("/alert/tickets", AlertSupportLive.Tickets, :index)
  #     live("/alert/ticket/:id", AlertSupportLive.Show, :show)
  #   end
  # end

  # Admin routes
  # scope "/admin", AnkaaWeb do
  #   pipe_through([:browser, :require_authenticated_user])

  #   live_session :admin,
  #     on_mount: [
  #       {AnkaaWeb.UserAuth, :ensure_authenticated},
  #       {AnkaaWeb.RoleAuth, :require_role, ["admin"]}
  #     ] do
  #     live("/users", Admin.UserLive.Index, :index)
  #     # live("/users/new", Admin.UserLive.Index, :new)
  #     # live("/users/:id/edit", Admin.UserLive.Index, :edit)
  #     # live("/users/:id", Admin.UserLive.Show, :show)
  #     # live("/users/:id/show/edit", Admin.UserLive.Show, :edit)
  #   end
  # end
end
