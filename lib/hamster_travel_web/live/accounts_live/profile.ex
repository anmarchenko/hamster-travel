defmodule HamsterTravelWeb.Accounts.Profile do
  @moduledoc """
  User profile
  """
  use HamsterTravelWeb, :live_view

  require Logger

  alias HamsterTravel.Accounts
  alias HamsterTravel.Planning

  @avatar_upload_max_mb 8
  @avatar_upload_max_file_size @avatar_upload_max_mb * 1_000_000
  @avatar_upload_accept ~w(.jpg .jpeg .png .webp)

  @impl true
  def mount(_params, _session, socket) do
    profile_stats = Planning.profile_stats(socket.assigns.current_user)

    socket =
      socket
      |> assign(
        page_title: gettext("My profile"),
        visited_countries: profile_stats.visited_countries,
        total_trips: profile_stats.total_trips,
        countries_count: profile_stats.countries,
        days_on_the_road: profile_stats.days_on_the_road,
        avatar_upload_errors: []
      )
      |> allow_upload(:avatar,
        accept: @avatar_upload_accept,
        max_entries: 1,
        max_file_size: @avatar_upload_max_file_size,
        auto_upload: true,
        progress: &handle_progress/3
      )

    {:ok, socket}
  end

  def handle_progress(:avatar, entry, socket) do
    %{current_user: user, uploads: uploads} = socket.assigns
    entry_errors = upload_errors(uploads.avatar, entry)

    if entry_errors != [] do
      socket =
        socket
        |> cancel_upload(:avatar, entry.ref)
        |> assign(avatar_upload_errors: Enum.uniq(entry_errors))

      {:noreply, socket}
    else
      if entry.done? do
        {temp_path, entry} =
          consume_uploaded_entry(socket, entry, fn %{path: path} ->
            {:ok, copy_upload_to_tmp(path, entry)}
          end)

        upload = %Plug.Upload{
          path: temp_path,
          filename: entry.client_name,
          content_type: entry.client_type
        }

        socket =
          case Accounts.update_user_avatar(user, upload) do
            {:ok, updated_user} ->
              File.rm(temp_path)

              socket
              |> assign(current_user: updated_user)
              |> assign(avatar_upload_errors: [])

            {:error, error} ->
              Logger.error(
                "Avatar upload failed in LiveView: user_id=#{user.id} file=#{entry.client_name} type=#{entry.client_type} reason=#{inspect(error)}"
              )

              File.rm(temp_path)

              socket
              |> assign(avatar_upload_errors: [:upload_failed])
              |> put_flash(:error, gettext("Failed to update avatar."))
          end

        {:noreply, socket}
      else
        {:noreply, socket}
      end
    end
  end

  @impl true
  def handle_event("validate_avatar", _params, socket) do
    upload = socket.assigns.uploads.avatar
    config_errors = upload_errors(upload)

    {socket, entry_errors} =
      Enum.reduce(upload.entries, {socket, []}, fn entry, {socket, errors} ->
        entry_errors = upload_errors(upload, entry)

        if entry_errors == [] do
          {socket, errors}
        else
          {cancel_upload(socket, :avatar, entry.ref), errors ++ entry_errors}
        end
      end)

    errors = Enum.uniq(config_errors ++ entry_errors)

    {:noreply, assign(socket, avatar_upload_errors: errors)}
  end

  @impl true
  def handle_event("remove_avatar", _params, socket) do
    user = socket.assigns.current_user

    socket =
      case Accounts.remove_user_avatar(user) do
        {:ok, updated_user} ->
          socket
          |> assign(current_user: updated_user)
          |> assign(avatar_upload_errors: [])
          |> put_flash(:info, gettext("Avatar removed."))

        {:error, changeset} ->
          Logger.error(
            "Avatar removal failed in LiveView: user_id=#{user.id} errors=#{inspect(changeset.errors)}"
          )

          put_flash(socket, :error, gettext("Failed to remove avatar."))
      end

    {:noreply, socket}
  end

  defp avatar_error(:too_large),
    do: gettext("File is too large. Maximum size is %{size} MB.", size: @avatar_upload_max_mb)

  defp avatar_error(:too_many_files), do: gettext("Only one image can be uploaded at a time.")
  defp avatar_error(:not_accepted), do: gettext("Unsupported file type. Use JPG, PNG, or WebP.")
  defp avatar_error(:upload_failed), do: gettext("Upload failed. Please try again.")
  defp avatar_error(_), do: gettext("Upload failed. Please try again.")

  defp avatar_uploading?(upload) do
    Enum.any?(upload.entries, fn entry ->
      not entry.done? and upload_errors(upload, entry) == []
    end)
  end

  defp copy_upload_to_tmp(path, entry) do
    extension = Path.extname(entry.client_name)
    filename = "user-avatar-#{entry.uuid}#{extension}"
    temp_path = Path.join(System.tmp_dir!(), filename)

    File.cp!(path, temp_path)

    {temp_path, entry}
  end
end
