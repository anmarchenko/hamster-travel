defmodule HamsterTravel.MixProject do
  use Mix.Project

  def project do
    [
      app: :hamster_travel,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      elixirc_options: [
        warnings_as_errors: false
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {HamsterTravel.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # phoenix base
      {:phoenix, "~> 1.7.0"},
      {:plug_cowboy, "~> 2.5"},

      # password hashing
      {:bcrypt_elixir, "~> 3.0"},

      # database
      {:ecto_sql, "~> 3.6"},
      {:phoenix_ecto, "~> 4.4"},
      {:postgrex, ">= 0.0.0"},
      {:ecto_autoslug_field, "~> 3.0"},

      # frontend
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_view, "~> 0.18.0"},
      {:petal_components, "~> 1.0"},
      {:esbuild, "~> 0.2", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.1", runtime: Mix.env() == :dev},

      # mails
      {:swoosh, "~> 1.3"},

      # http client
      {:finch, "~> 0.13"},

      # observability
      {:phoenix_live_dashboard, "~> 0.7.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},

      # i18n
      {:gettext, "~> 0.22"},

      # json
      {:jason, "~> 1.2"},

      # yaml parsing
      {:yaml_elixir, "~> 2.9"},

      # math
      {:abacus, "~> 2.0"},

      # locale info, dates and money formatting
      {:ex_cldr, "~> 2.23"},
      {:ex_cldr_dates_times, "~> 2.0"},
      {:ex_cldr_numbers, "~> 2.0"},

      # test/lint/dev tools
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:floki, ">= 0.30.0", only: :test},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "cmd --cd assets npm install", "esbuild default"],
      "assets.deploy": [
        "tailwind default --minify",
        "cmd --cd assets npm install",
        "esbuild default --minify",
        "phx.digest"
      ],
      gettext: [
        "gettext.extract",
        "gettext.merge priv/gettext/en/LC_MESSAGES/default.po priv/gettext/default.pot",
        "gettext.merge priv/gettext/ru/LC_MESSAGES/default.po priv/gettext/default.pot"
      ]
    ]
  end
end
