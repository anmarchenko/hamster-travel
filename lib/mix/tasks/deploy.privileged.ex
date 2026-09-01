defmodule HamsterTravel.MixTasks.Privileged do
  @moduledoc false

  @environment "/usr/bin/env"
  @pkexec "/usr/bin/pkexec"

  @spec run!(String.t(), [String.t()], keyword()) :: :ok
  def run!(executable, arguments, options \\ []) do
    environment =
      options
      |> Keyword.get(:preserve_environment, [])
      |> Enum.flat_map(fn name ->
        case System.get_env(name) do
          nil -> []
          value -> [name <> "=" <> value]
        end
      end)

    command =
      case environment do
        [] -> [executable | arguments]
        values -> [@environment | values ++ [executable | arguments]]
      end

    {_output, status} =
      System.cmd(@pkexec, command,
        into: IO.stream(:stdio, :line),
        stderr_to_stdout: true
      )

    if status != 0 do
      Mix.raise("privileged command exited with status #{status}")
    end

    :ok
  end
end

defmodule Mix.Tasks.Deploy.Privileged do
  @moduledoc false
  use Mix.Task

  @deploy_binary "/usr/local/sbin/hamster-deploy"
  @deploy_environment [
    "HAMSTER_DEPLOY_SOURCE_DIR",
    "HAMSTER_DEPLOY_INFRA_DIR",
    "HAMSTER_DEPLOY_COMPOSE_FILE",
    "HAMSTER_DEPLOY_APP_ENV_FILE",
    "HAMSTER_DEPLOY_DATABASE_ENV_FILE",
    "HAMSTER_DEPLOY_INFRA_ENV_FILE",
    "HAMSTER_DEPLOY_BACKUP_MARKER",
    "HAMSTER_DEPLOY_LOCK_FILE",
    "HAMSTER_DEPLOY_IMAGE",
    "HAMSTER_DEPLOY_DATABASE_CONTAINER",
    "HAMSTER_DEPLOY_NETWORK_INTERFACE",
    "HAMSTER_DEPLOY_REQUIRED_ADDRESS",
    "HAMSTER_DEPLOY_LOCAL_HEALTH_URL",
    "HAMSTER_DEPLOY_PUBLIC_HEALTH_URL",
    "HAMSTER_DEPLOY_HEALTH_TIMEOUT",
    "HAMSTER_DEPLOY_MAX_BACKUP_AGE",
    "HAMSTER_DEPLOY_DOCKER",
    "HAMSTER_DEPLOY_GIT"
  ]

  @impl Mix.Task
  def run(arguments) do
    HamsterTravel.MixTasks.Privileged.run!(@deploy_binary, arguments,
      preserve_environment: @deploy_environment
    )
  end
end

defmodule Mix.Tasks.Deploy.Install do
  @moduledoc false
  use Mix.Task

  @impl Mix.Task
  def run([]) do
    HamsterTravel.MixTasks.Privileged.run!("/usr/bin/install", [
      "--owner=root",
      "--group=root",
      "--mode=0755",
      "/tmp/hamster-deploy",
      "/usr/local/sbin/hamster-deploy"
    ])
  end

  def run(_arguments), do: Mix.raise("usage: mix deploy.build")
end
