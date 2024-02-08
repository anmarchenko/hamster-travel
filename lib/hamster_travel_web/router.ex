defmodule HamsterTravelWeb.Router do
  use HamsterTravelWeb, :router

  import HamsterTravelWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {HamsterTravelWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HamsterTravelWeb do
    pipe_through :browser

    live_session :authenticated,
      on_mount: [
        {HamsterTravelWeb.UserAuth, :ensure_authenticated}
      ] do
      live "/drafts", Planning.IndexDrafts
      live "/trips/new", Planning.CreateTrip

      live "/backpacks", Packing.IndexBackpacks
      live "/backpacks/new", Packing.CreateBackpack
      live "/backpacks/:backpack_slug", Packing.ShowBackpack
      live "/backpacks/:backpack_slug/edit", Packing.EditBackpack

      live "/profile", Accounts.Profile
    end

    live_session :default,
      on_mount: [
        {HamsterTravelWeb.UserAuth, :mount_current_user}
      ] do
      live "/", Home

      live "/plans", Planning.IndexPlans
      live "/trips/:trip_slug", Planning.ShowTrip
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", HamsterTravelWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: HamsterTravelWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", HamsterTravelWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{HamsterTravelWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", HamsterTravelWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{HamsterTravelWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", HamsterTravelWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{HamsterTravelWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
