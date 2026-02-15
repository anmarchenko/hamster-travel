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
    "CHROMIC_PDF_DISABLE_DEV_SHM_USAGE"
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

  test "chromic pdf session pool has explicit init timeout in prod config" do
    config = Config.Reader.read!(@runtime_path, env: :prod)

    chromic_pdf_opts =
      config
      |> Keyword.fetch!(:hamster_travel)
      |> Keyword.fetch!(ChromicPDF)

    session_pool_opts = Keyword.fetch!(chromic_pdf_opts, :session_pool)

    assert Keyword.fetch!(chromic_pdf_opts, :on_demand) == false
    assert Keyword.fetch!(session_pool_opts, :timeout) == 60_000
    assert Keyword.fetch!(session_pool_opts, :init_timeout) == 60_000
    assert Keyword.fetch!(session_pool_opts, :checkout_timeout) == 60_000
    assert Keyword.fetch!(chromic_pdf_opts, :chrome_args) == "--disable-dev-shm-usage"
  end
end
