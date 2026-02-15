defmodule HamsterTravel.Config.RuntimeTest do
  use ExUnit.Case, async: false

  @runtime_path Path.expand("../../config/runtime.exs", __DIR__)
  @required_env %{
    "DATABASE_URL" => "ecto://user:pass@localhost/hamster_travel_prod",
    "SECRET_KEY_BASE" => "runtime-test-secret",
    "PHX_HOST" => "example.com",
    "OPEN_EXCHANGE_RATES_APP_ID" => "test-app-id"
  }

  setup do
    original_values =
      Map.new(@required_env, fn {key, _value} ->
        {key, System.get_env(key)}
      end)

    Enum.each(@required_env, fn {key, value} ->
      System.put_env(key, value)
    end)

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
end
