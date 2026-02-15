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
    pipe_through [:browser, :require_authenticated_user]

    delete "/users/log_out", UserSessionController, :delete
    get "/trips/:trip_slug/export.pdf", TripPdfController, :show

    live_session :authenticated,
      on_mount: [
        {HamsterTravelWeb.UserAuth, :ensure_authenticated}
      ] do
      live "/", Planning.IndexPlans
      live "/plans", Planning.IndexPlans
      live "/drafts", Planning.IndexDrafts
      live "/trips/new", Planning.CreateTrip
      live "/trips/:trip_slug", Planning.ShowTrip
      live "/trips/:trip_slug/edit", Planning.EditTrip

      live "/backpacks", Packing.IndexBackpacks
      live "/backpacks/new", Packing.CreateBackpack
      live "/backpacks/:backpack_slug", Packing.ShowBackpack
      live "/backpacks/:backpack_slug/edit", Packing.EditBackpack

      live "/profile", Accounts.Profile
      live "/users/settings", UserSettingsLive, :edit
    end
  end

  ## Authentication routes
  scope "/", HamsterTravelWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{HamsterTravelWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/log_in", UserLoginLive, :new
    end

    post "/users/log_in", UserSessionController, :create
  end

  # Other scopes may use custom stacks.
  # scope "/api", HamsterTravelWeb do
  #   pipe_through :api
  # end

  # Dev tools

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
end
