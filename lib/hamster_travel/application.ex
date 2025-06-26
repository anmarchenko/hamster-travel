defmodule HamsterTravel.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      HamsterTravel.Repo,
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
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HamsterTravelWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
