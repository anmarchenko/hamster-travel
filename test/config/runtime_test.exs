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
    "CHROMIC_PDF_GHOSTSCRIPT_POOL_SIZE",
    "CHROME_BIN",
    "CHROMIC_PDF_POOL_SIZE",
    "PHX_CHECK_ORIGINS",
    "PHX_PORT",
    "PHX_SCHEME",
    "POOL_SIZE",
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

    assert config
           |> hamster_travel_config()
           |> Keyword.fetch!(:warm_chromic_pdf)
  end

  test "stale TRIP_PDF_RENDERER=flame env is ignored" do
    System.put_env("TRIP_PDF_RENDERER", "flame")

    config = read_prod_config()

    assert config
           |> hamster_travel_config()
           |> Keyword.fetch!(:trip_pdf_renderer) == HamsterTravelWeb.TripPdf.ChromicRenderer
  end

  test "repo runtime config uses POOL_SIZE" do
    System.put_env("POOL_SIZE", "25")

    config = read_prod_config()

    repo_config =
      config
      |> hamster_travel_config()
      |> Keyword.fetch!(HamsterTravel.Repo)

    assert Keyword.fetch!(repo_config, :pool_size) == 25
  end

  test "endpoint permits only the canonical origin by default" do
    endpoint_config =
      read_prod_config()
      |> hamster_travel_config()
      |> Keyword.fetch!(HamsterTravelWeb.Endpoint)

    assert Keyword.fetch!(endpoint_config, :check_origin) == ["https://example.com"]
  end

  test "endpoint accepts an explicit origin allowlist" do
    System.put_env("PHX_CHECK_ORIGINS", "http://127.0.0.1:4400, https://hamster.example.ts.net")

    endpoint_config =
      read_prod_config()
      |> hamster_travel_config()
      |> Keyword.fetch!(HamsterTravelWeb.Endpoint)

    assert Keyword.fetch!(endpoint_config, :check_origin) == [
             "http://127.0.0.1:4400",
             "https://hamster.example.ts.net"
           ]
  end

  test "endpoint rejects wildcard origins" do
    System.put_env("PHX_CHECK_ORIGINS", "https://*.example.com")

    assert_raise RuntimeError, ~r/explicit comma-separated HTTP\(S\) origins/, fn ->
      read_prod_config()
    end
  end

  test "chromic pdf session pool has explicit init timeout in prod config" do
    config = read_prod_config()

    chromic_pdf_opts =
      config
      |> hamster_travel_config()
      |> Keyword.fetch!(ChromicPDF)

    session_pool_opts = Keyword.fetch!(chromic_pdf_opts, :session_pool)

    assert Keyword.fetch!(chromic_pdf_opts, :on_demand) == false
    assert Keyword.fetch!(session_pool_opts, :size) == 4
    assert Keyword.fetch!(session_pool_opts, :timeout) == 60_000
    assert Keyword.fetch!(session_pool_opts, :init_timeout) == 60_000
    assert Keyword.fetch!(session_pool_opts, :checkout_timeout) == 60_000
    assert Keyword.fetch!(session_pool_opts, :max_uses) == 500
    assert Keyword.fetch!(chromic_pdf_opts, :ghostscript_pool) == [size: 2]
    assert Keyword.fetch!(chromic_pdf_opts, :chrome_args) == nil
  end

  test "chromic PDF pool sizes are configurable" do
    System.put_env("CHROMIC_PDF_POOL_SIZE", "6")
    System.put_env("CHROMIC_PDF_GHOSTSCRIPT_POOL_SIZE", "3")

    chromic_pdf_opts =
      read_prod_config()
      |> hamster_travel_config()
      |> Keyword.fetch!(ChromicPDF)

    assert chromic_pdf_opts[:session_pool][:size] == 6
    assert chromic_pdf_opts[:ghostscript_pool][:size] == 3
  end

  defp read_prod_config do
    Config.Reader.read!(@runtime_path, env: :prod)
  end

  defp hamster_travel_config(config) do
    Keyword.fetch!(config, :hamster_travel)
  end
end
