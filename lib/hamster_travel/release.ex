defmodule HamsterTravel.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :hamster_travel

  alias HamsterTravel.Accounts.UserAvatar

  @waffle_check_image Base.decode64!(
                        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
                      )

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  @doc """
  Verifies production Waffle storage with a disposable avatar upload.

  The check uploads both avatar versions, fetches their public URLs, removes
  them, and confirms the S3 objects no longer exist.
  """
  def verify_waffle_storage do
    ensure_started!(:req)

    scope = %{id: "waffle-production-check-#{System.unique_integer([:positive, :monotonic])}"}
    file_name = "waffle-production-check.png"
    upload = %{binary: @waffle_check_image, filename: file_name}
    file_and_scope = {file_name, scope}
    version_urls = Map.new(UserAvatar.__versions(), &{&1, UserAvatar.url(file_and_scope, &1)})

    check_result =
      try do
        assert_stored!(UserAvatar.store({upload, scope}), file_name)

        Enum.each(version_urls, fn {version, url} ->
          assert_public_object!(url, version)
        end)

        :ok
      rescue
        exception -> {:error, exception, __STACKTRACE__}
      after
        :ok = UserAvatar.delete(file_and_scope)
      end

    Enum.each(version_urls, fn {version, url} ->
      assert_deleted_object!(url, version)
    end)

    case check_result do
      :ok ->
        IO.puts("Waffle production storage check passed: upload, public fetch, delete, cleanup")

      {:error, exception, stacktrace} ->
        reraise exception, stacktrace
    end
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end

  defp ensure_started!(application) do
    case Application.ensure_all_started(application) do
      {:ok, _started} -> :ok
      {:error, reason} -> raise "could not start #{application}: #{inspect(reason)}"
    end
  end

  defp assert_stored!({:ok, file_name}, file_name), do: :ok

  defp assert_stored!({:error, errors}, _file_name) when is_list(errors) do
    raise "Waffle upload failed for #{length(errors)} version(s); verify the bucket and uploader permissions"
  end

  defp assert_stored!({:error, _reason}, _file_name) do
    raise "Waffle upload failed; verify the bucket and uploader permissions"
  end

  defp assert_public_object!(url, version) do
    case Req.get(url) do
      {:ok, %{status: 200, body: body}} when byte_size(body) > 0 ->
        :ok

      {:ok, response} ->
        raise "Waffle #{version} URL returned HTTP #{response.status}"

      {:error, reason} ->
        raise "Waffle #{version} URL fetch failed: #{inspect(reason)}"
    end
  end

  defp assert_deleted_object!(url, version) do
    case Req.get(url) do
      {:ok, %{status: status}} when status in [403, 404] ->
        :ok

      {:ok, %{status: 200}} ->
        raise "Waffle cleanup left the public #{version} object in S3"

      {:ok, response} ->
        raise "Waffle #{version} URL returned HTTP #{response.status} after cleanup"

      {:error, reason} ->
        raise "Waffle #{version} URL cleanup check failed: #{inspect(reason)}"
    end
  end
end
