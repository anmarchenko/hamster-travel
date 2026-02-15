defmodule HamsterTravel.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    chromic_pdf_opts = Application.get_env(:hamster_travel, ChromicPDF, [])

    children = [
      # Start the Ecto repository
      HamsterTravel.Repo,
      {ChromicPDF, chromic_pdf_opts},
      # Start the Telemetry supervisor
      HamsterTravelWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: HamsterTravel.PubSub},
      # Start the Endpoint (http/https)
      HamsterTravelWeb.Endpoint
      # Start a worker by calling: HamsterTravel.Worker.start_link(arg)
      # {HamsterTravel.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HamsterTravel.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        log_storage_startup_check()
        {:ok, pid}

      error ->
        error
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HamsterTravelWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp log_storage_startup_check do
    waffle_storage = Application.get_env(:waffle, :storage)

    if waffle_storage == Waffle.Storage.S3 do
      bucket = resolve_config_value(Application.get_env(:waffle, :bucket))
      asset_host = resolve_config_value(Application.get_env(:waffle, :asset_host))
      region = resolve_config_value(Application.get_env(:ex_aws, :region))
      access_key = summarize_access_key_source(Application.get_env(:ex_aws, :access_key_id))

      Logger.info(
        "Storage startup check: storage=s3 bucket=#{present_or_missing(bucket)} asset_host=#{present_or_missing(asset_host)} region=#{present_or_missing(region)}"
      )

      missing =
        []
        |> maybe_add_missing(bucket, "AWS_S3_BUCKET")
        |> maybe_add_missing(asset_host, "S3_ASSET_HOST")
        |> maybe_add_missing(region, "AWS_REGION")
        |> maybe_add_missing(access_key, "AWS_ACCESS_KEY_ID / instance role")

      if missing != [] do
        Logger.warning(
          "Storage startup check: missing or unresolved config #{Enum.join(missing, ", ")}"
        )
      end
    end
  end

  defp maybe_add_missing(missing, nil, key), do: missing ++ [key]
  defp maybe_add_missing(missing, "MISSING", key), do: missing ++ [key]
  defp maybe_add_missing(missing, _value, _key), do: missing

  defp present_or_missing(nil), do: "MISSING"
  defp present_or_missing(value), do: value

  defp resolve_config_value({:system, env_var}) when is_binary(env_var),
    do: System.get_env(env_var)

  defp resolve_config_value(value) when is_binary(value), do: value
  defp resolve_config_value(_), do: nil

  defp summarize_access_key_source(config) when is_list(config) do
    case Enum.find_value(config, &resolve_access_key_source/1) do
      nil -> "MISSING"
      value -> value
    end
  end

  defp summarize_access_key_source(config) do
    case resolve_access_key_source(config) do
      nil -> "MISSING"
      value -> value
    end
  end

  defp resolve_access_key_source({:system, env_var}) when is_binary(env_var) do
    case System.get_env(env_var) do
      nil -> nil
      key -> "env:#{env_var}:#{mask_key(key)}"
    end
  end

  defp resolve_access_key_source(:instance_role), do: "instance_role"
  defp resolve_access_key_source(_), do: nil

  defp mask_key(key) when is_binary(key) do
    key
    |> String.slice(0, 4)
    |> Kernel.||("")
    |> Kernel.<>("***")
  end
end
