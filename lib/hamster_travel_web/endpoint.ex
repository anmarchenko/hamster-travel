defmodule HamsterTravelWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :hamster_travel

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_hamster_travel_key",
    signing_salt: "EgoTh/Qh",
    max_age: 365 * 24 * 60 * 60
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [compress: true, connect_info: [session: @session_options]]

  # esbuild gives these optional feature chunks content-hashed filenames.
  # Their import URLs do not carry Phoenix's ?vsn= query string.
  plug Plug.Static,
    at: "/assets/chunks",
    from: {:hamster_travel, "priv/static/assets/chunks"},
    gzip: Application.compile_env(:hamster_travel, :static_gzip, false),
    cache_control_for_etags: "public, max-age=31536000, immutable"

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :hamster_travel,
    gzip: Application.compile_env(:hamster_travel, :static_gzip, false),
    only: HamsterTravelWeb.static_paths()

  if Code.ensure_loaded?(Tidewave) do
    plug Tidewave, toolbar: false
  end

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :hamster_travel
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug HamsterTravelWeb.Router
end
