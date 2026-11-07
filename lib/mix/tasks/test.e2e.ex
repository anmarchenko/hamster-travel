defmodule Mix.Tasks.Test.E2e do
  use Mix.Task

  @shortdoc "Builds the assets and runs the Chromium end-to-end suite"

  @e2e_dir "test/e2e"

  @impl Mix.Task
  def run(args) do
    if Mix.env() != :test, do: Mix.raise("Run mix test.e2e with MIX_ENV=test.")

    unless File.regular?(Path.join(@e2e_dir, "node_modules/@playwright/test/package.json")) do
      Mix.raise("Install the browser test dependencies with npm ci --prefix test/e2e.")
    end

    executable = System.get_env("E2E_CHROMIUM") || bundled_chromium!()
    executable = Path.expand(executable)

    unless System.find_executable(executable) do
      Mix.raise("Install Chromium with cd test/e2e && npm exec -- playwright install chromium.")
    end

    System.put_env("E2E_CHROMIUM", executable)
    Mix.Task.run("assets.build")
    Mix.Task.run("test", [Path.join(@e2e_dir, "browser_test.exs"), "--only", "e2e" | args])
  end

  defp bundled_chromium! do
    case System.cmd("node", ["-p", "require('@playwright/test').chromium.executablePath()"],
           cd: @e2e_dir,
           stderr_to_stdout: true
         ) do
      {path, 0} -> String.trim(path)
      {output, _status} -> Mix.raise("Could not find Playwright Chromium.\n#{output}")
    end
  end
end
