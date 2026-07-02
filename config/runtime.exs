import Config

config :hamster_travel, :mapbox,
  access_token: System.get_env("MAPBOX_ACCESS_TOKEN"),
  style_url: System.get_env("MAPBOX_STYLE_URL")

env_true? = fn value ->
  value
  |> to_string()
  |> String.downcase()
  |> then(&(&1 in ["1", "true", "yes", "on"]))
end

trip_pdf_renderer =
  case System.get_env("TRIP_PDF_RENDERER", "chromic") |> String.trim() |> String.downcase() do
    "chromic" ->
      HamsterTravelWeb.TripPdf.ChromicRenderer

    "flame" ->
      HamsterTravelWeb.TripPdf.FlameChromicRenderer

    value ->
      raise """
      unsupported TRIP_PDF_RENDERER=#{inspect(value)}.
      Expected "chromic" or "flame".
      """
  end

config :hamster_travel, :trip_pdf_renderer, trip_pdf_renderer

config :hamster_travel,
  trip_pdf_flame_fallback:
    System.get_env("TRIP_PDF_FLAME_FALLBACK", "true")
    |> env_true?.(),
  trip_pdf_flame_timeout: String.to_integer(System.get_env("TRIP_PDF_FLAME_TIMEOUT") || "120000")

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.
if config_env() == :prod do
  flame_parent = FLAME.Parent.get()

  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  pool_size =
    if flame_parent do
      1
    else
      String.to_integer(System.get_env("POOL_SIZE") || "10")
    end

  config :hamster_travel, HamsterTravel.Repo,
    ssl: false,
    socket_options: [:inet6],
    url: database_url,
    pool_size: pool_size

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  phx_host = System.get_env("PHX_HOST")

  config :hamster_travel, HamsterTravelWeb.Endpoint,
    server: true,
    url: [host: phx_host, port: 80],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: 4000
    ],
    secret_key_base: secret_key_base

  config :hamster_travel, HamsterTravelWeb.Telemetry,
    report_metrics: true,
    periodic_measurements_enabled: false

  chromic_pdf_on_demand? =
    System.get_env("CHROMIC_PDF_ON_DEMAND", "false")
    |> env_true?.()

  chromic_pdf_no_sandbox? =
    System.get_env("CHROMIC_PDF_NO_SANDBOX", "true")
    |> env_true?.()

  chromic_pdf_discard_stderr? =
    System.get_env("CHROMIC_PDF_DISCARD_STDERR", "true")
    |> env_true?.()

  chromic_pdf_disable_dev_shm_usage? =
    System.get_env("CHROMIC_PDF_DISABLE_DEV_SHM_USAGE", "true")
    |> env_true?.()

  chrome_args =
    if chromic_pdf_disable_dev_shm_usage? do
      "--disable-dev-shm-usage"
    else
      nil
    end

  config :hamster_travel, ChromicPDF,
    on_demand: chromic_pdf_on_demand?,
    no_sandbox: chromic_pdf_no_sandbox?,
    discard_stderr: chromic_pdf_discard_stderr?,
    chrome_args: chrome_args,
    chrome_executable: System.get_env("CHROME_BIN", "/usr/bin/chromium"),
    session_pool: [size: 1, timeout: 60_000, init_timeout: 60_000, checkout_timeout: 60_000],
    ghostscript_pool: [size: 1]

  open_exchange_rates_app_id = System.fetch_env!("OPEN_EXCHANGE_RATES_APP_ID")

  config :ex_money,
    auto_start_exchange_rate_service: true,
    # 2 hours
    exchange_rates_retrieve_every: 7_200_000,
    open_exchange_rates_app_id: open_exchange_rates_app_id

  fly_api_token =
    case {trip_pdf_renderer, System.get_env("FLY_API_TOKEN")} do
      {HamsterTravelWeb.TripPdf.FlameChromicRenderer, nil} ->
        raise """
        environment variable FLY_API_TOKEN is missing.
        It is required when TRIP_PDF_RENDERER=flame.
        """

      {_renderer, token} ->
        token
    end

  fly_backend_opts = [
    cpu_kind: "shared",
    cpus: 1,
    memory_mb: 1024,
    services: [],
    env: %{
      "DATABASE_URL" => database_url,
      "SECRET_KEY_BASE" => secret_key_base,
      "PHX_HOST" => phx_host || "",
      "OPEN_EXCHANGE_RATES_APP_ID" => open_exchange_rates_app_id,
      "CHROME_BIN" => System.get_env("CHROME_BIN", "/usr/bin/chromium"),
      "POOL_SIZE" => "1",
      "CHROMIC_PDF_ON_DEMAND" => "false"
    }
  ]

  fly_backend_opts =
    if fly_api_token do
      Keyword.put(fly_backend_opts, :token, fly_api_token)
    else
      fly_backend_opts
    end

  config :flame, :backend, FLAME.FlyBackend
  config :flame, FLAME.FlyBackend, fly_backend_opts
end
