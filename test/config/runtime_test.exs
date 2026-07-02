defmodule HamsterTravel.Config.RuntimeTest do
  use ExUnit.Case, async: false

  @runtime_path Path.expand("../../config/runtime.exs", __DIR__)
  @required_env %{
    "DATABASE_URL" => "ecto://user:pass@localhost/hamster_travel_prod",
    "SECRET_KEY_BASE" => "runtime-test-secret",
    "PHX_HOST" => "example.com",
    "OPEN_EXCHANGE_RATES_APP_ID" => "test-app-id"
  }
  @defaulted_env [
    "CHROMIC_PDF_ON_DEMAND",
    "CHROMIC_PDF_NO_SANDBOX",
    "CHROMIC_PDF_DISCARD_STDERR",
    "CHROMIC_PDF_DISABLE_DEV_SHM_USAGE",
    "CHROME_BIN",
    "FLAME_PARENT",
    "FLY_API_TOKEN",
    "POOL_SIZE",
    "TRIP_PDF_FLAME_FALLBACK",
    "TRIP_PDF_FLAME_TIMEOUT",
    "TRIP_PDF_RENDERER"
  ]

  setup do
    managed_keys = Map.keys(@required_env) ++ @defaulted_env

    original_values =
      Map.new(managed_keys, fn key ->
        {key, System.get_env(key)}
      end)

    Enum.each(@required_env, fn {key, value} ->
      System.put_env(key, value)
    end)

    Enum.each(@defaulted_env, &System.delete_env/1)

    on_exit(fn ->
      Enum.each(original_values, fn
        {key, nil} -> System.delete_env(key)
        {key, value} -> System.put_env(key, value)
      end)
    end)

    :ok
  end

  test "runtime.exs can be evaluated for prod" do
    assert is_list(Config.Reader.read!(@runtime_path, env: :prod))
  end

  test "trip PDF renderer defaults to local ChromicPDF in prod config" do
    config = read_prod_config()

    assert config
           |> hamster_travel_config()
           |> Keyword.fetch!(:trip_pdf_renderer) == HamsterTravelWeb.TripPdf.ChromicRenderer
  end

  test "TRIP_PDF_RENDERER=flame selects FLAME renderer and Fly backend config" do
    System.put_env("TRIP_PDF_RENDERER", "flame")
    System.put_env("FLY_API_TOKEN", "runtime-test-fly-token")

    config = read_prod_config()

    assert config
           |> hamster_travel_config()
           |> Keyword.fetch!(:trip_pdf_renderer) == HamsterTravelWeb.TripPdf.FlameChromicRenderer

    fly_backend_opts =
      config
      |> Keyword.fetch!(:flame)
      |> Keyword.fetch!(FLAME.FlyBackend)

    assert Keyword.fetch!(fly_backend_opts, :token) == "runtime-test-fly-token"
    assert Keyword.fetch!(fly_backend_opts, :cpu_kind) == "shared"
    assert Keyword.fetch!(fly_backend_opts, :cpus) == 1
    assert Keyword.fetch!(fly_backend_opts, :memory_mb) == 1024
    assert Keyword.fetch!(fly_backend_opts, :services) == []

    runner_env = Keyword.fetch!(fly_backend_opts, :env)
    assert runner_env["DATABASE_URL"] == "ecto://user:pass@localhost/hamster_travel_prod"
    assert runner_env["SECRET_KEY_BASE"] == "runtime-test-secret"
    assert runner_env["PHX_HOST"] == "example.com"
    assert runner_env["OPEN_EXCHANGE_RATES_APP_ID"] == "test-app-id"
    assert runner_env["CHROME_BIN"] == "/usr/bin/chromium"
    assert runner_env["POOL_SIZE"] == "1"
    assert runner_env["CHROMIC_PDF_ON_DEMAND"] == "false"
  end

  test "TRIP_PDF_RENDERER=flame requires FLY_API_TOKEN in prod config" do
    System.put_env("TRIP_PDF_RENDERER", "flame")

    assert_raise RuntimeError, ~r/FLY_API_TOKEN is missing/, fn ->
      read_prod_config()
    end
  end

  test "FLAME child runtime config uses DB pool size 1" do
    System.put_env("POOL_SIZE", "25")
    System.put_env("FLAME_PARENT", encoded_flame_parent())

    config = read_prod_config()

    repo_config =
      config
      |> hamster_travel_config()
      |> Keyword.fetch!(HamsterTravel.Repo)

    assert Keyword.fetch!(repo_config, :pool_size) == 1
  end

  test "chromic pdf session pool has explicit init timeout in prod config" do
    config = read_prod_config()

    chromic_pdf_opts =
      config
      |> hamster_travel_config()
      |> Keyword.fetch!(ChromicPDF)

    session_pool_opts = Keyword.fetch!(chromic_pdf_opts, :session_pool)

    assert Keyword.fetch!(chromic_pdf_opts, :on_demand) == false
    assert Keyword.fetch!(session_pool_opts, :timeout) == 60_000
    assert Keyword.fetch!(session_pool_opts, :init_timeout) == 60_000
    assert Keyword.fetch!(session_pool_opts, :checkout_timeout) == 60_000
    assert Keyword.fetch!(chromic_pdf_opts, :chrome_args) == "--disable-dev-shm-usage"
  end

  defp read_prod_config do
    Config.Reader.read!(@runtime_path, env: :prod)
  end

  defp hamster_travel_config(config) do
    Keyword.fetch!(config, :hamster_travel)
  end

  defp encoded_flame_parent do
    make_ref()
    |> FLAME.Parent.new(self(), FLAME.LocalBackend, "runtime-test-flame", "HOSTNAME")
    |> FLAME.Parent.encode()
  end
end
