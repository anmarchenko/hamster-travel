defmodule HamsterTravelWeb.Accounts.Profile do
  @moduledoc """
  User profile
  """
  use HamsterTravelWeb, :live_view

  require Logger

  alias HamsterTravel.Accounts
  alias HamsterTravel.Accounts.VisitedCity
  alias HamsterTravel.Geo
  alias HamsterTravel.Planning
  alias HamsterTravelWeb.CityInput

  @avatar_upload_max_mb 8
  @avatar_upload_max_file_size @avatar_upload_max_mb * 1_000_000
  @avatar_upload_accept ~w(.jpg .jpeg .png .webp)
  @cover_upload_max_mb 8
  @cover_upload_max_file_size @cover_upload_max_mb * 1_000_000
  @cover_upload_accept ~w(.jpg .jpeg .png .webp)
  @mapbox_style "mapbox://styles/altmer/cj11tgfi0005s2so7k1yl6w81"

  @impl true
  def mount(_params, _session, socket) do
    mapbox_options = Application.get_env(:hamster_travel, :mapbox, [])
    mapbox_style_url = Keyword.get(mapbox_options, :style_url) || @mapbox_style

    socket =
      socket
      |> assign(
        page_title: gettext("My profile"),
        mapbox_access_token: Keyword.get(mapbox_options, :access_token),
        mapbox_style_url: mapbox_style_url,
        avatar_upload_errors: [],
        cover_upload_errors: [],
        show_visited_cities_modal: false
      )
      |> assign_profile_data()
      |> allow_upload(:avatar,
        accept: @avatar_upload_accept,
        max_entries: 1,
        max_file_size: @avatar_upload_max_file_size,
        auto_upload: true,
        progress: &handle_progress/3
      )
      |> allow_upload(:cover,
        accept: @cover_upload_accept,
        max_entries: 1,
        max_file_size: @cover_upload_max_file_size,
        auto_upload: true,
        progress: &handle_progress/3
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("open_visited_cities_modal", _params, socket) do
    {:noreply, assign(socket, :show_visited_cities_modal, true)}
  end

  @impl true
  def handle_event("close_visited_cities_modal", _params, socket) do
    {:noreply, assign(socket, :show_visited_cities_modal, false)}
  end

  @impl true
  def handle_event("save_visited_city", %{"visited_city" => visited_city_params}, socket) do
    visited_city_params = CityInput.process_selected_value_on_submit(visited_city_params, "city")

    case Accounts.create_visited_city(socket.assigns.current_user, visited_city_params) do
      {:ok, _visited_city} ->
        {:noreply,
         socket
         |> assign_profile_data()
         |> assign(:show_visited_cities_modal, true)}

      {:error, changeset} ->
        {:noreply, assign(socket, :visited_city_form, visited_city_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete_visited_city", %{"id" => id}, socket) do
    case Accounts.delete_visited_city(socket.assigns.current_user, id) do
      {:ok, _visited_city} ->
        {:noreply, assign_profile_data(socket)}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, gettext("Visited city not found."))}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to delete visited city."))}
    end
  end

  @impl true
  def handle_event("validate_avatar", _params, socket) do
    {:noreply, validate_upload(socket, :avatar, :avatar_upload_errors)}
  end

  @impl true
  def handle_event("validate_cover", _params, socket) do
    {:noreply, validate_upload(socket, :cover, :cover_upload_errors)}
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

  @impl true
  def handle_event("remove_cover", _params, socket) do
    user = socket.assigns.current_user

    socket =
      case Accounts.remove_user_cover(user) do
        {:ok, updated_user} ->
          socket
          |> assign(current_user: updated_user)
          |> assign(cover_upload_errors: [])
          |> put_flash(:info, gettext("Cover removed."))

        {:error, changeset} ->
          Logger.error(
            "Cover removal failed in LiveView: user_id=#{user.id} errors=#{inspect(changeset.errors)}"
          )

          put_flash(socket, :error, gettext("Failed to remove cover."))
      end

    {:noreply, socket}
  end

  def handle_progress(:avatar, entry, socket) do
    handle_user_upload_progress(
      entry,
      socket,
      :avatar,
      :avatar_upload_errors,
      "user-avatar",
      &Accounts.update_user_avatar/2,
      gettext("Failed to update avatar."),
      "Avatar"
    )
  end

  def handle_progress(:cover, entry, socket) do
    handle_user_upload_progress(
      entry,
      socket,
      :cover,
      :cover_upload_errors,
      "user-cover",
      &Accounts.update_user_cover/2,
      gettext("Failed to update cover."),
      "Cover"
    )
  end

  defp avatar_error(:too_large),
    do: gettext("File is too large. Maximum size is %{size} MB.", size: @avatar_upload_max_mb)

  defp avatar_error(:too_many_files), do: gettext("Only one image can be uploaded at a time.")
  defp avatar_error(:not_accepted), do: gettext("Unsupported file type. Use JPG, PNG, or WebP.")
  defp avatar_error(:upload_failed), do: gettext("Upload failed. Please try again.")
  defp avatar_error(_), do: gettext("Upload failed. Please try again.")

  defp cover_error(:too_large),
    do: gettext("File is too large. Maximum size is %{size} MB.", size: @cover_upload_max_mb)

  defp cover_error(:too_many_files), do: gettext("Only one image can be uploaded at a time.")
  defp cover_error(:not_accepted), do: gettext("Unsupported file type. Use JPG, PNG, or WebP.")
  defp cover_error(:upload_failed), do: gettext("Upload failed. Please try again.")
  defp cover_error(_), do: gettext("Upload failed. Please try again.")

  defp avatar_uploading?(upload) do
    uploading?(upload)
  end

  defp cover_uploading?(upload) do
    uploading?(upload)
  end

  defp uploading?(upload) do
    Enum.any?(upload.entries, fn entry ->
      not entry.done? and upload_errors(upload, entry) == []
    end)
  end

  defp validate_upload(socket, upload_name, upload_error_assign) do
    upload = Map.fetch!(socket.assigns.uploads, upload_name)
    config_errors = upload_errors(upload)

    {socket, entry_errors} =
      Enum.reduce(upload.entries, {socket, []}, fn entry, {socket, errors} ->
        entry_errors = upload_errors(upload, entry)

        if entry_errors == [] do
          {socket, errors}
        else
          {cancel_upload(socket, upload_name, entry.ref), errors ++ entry_errors}
        end
      end)

    assign(socket, upload_error_assign, Enum.uniq(config_errors ++ entry_errors))
  end

  defp handle_user_upload_progress(
         entry,
         socket,
         upload_name,
         upload_error_assign,
         tmp_filename_prefix,
         update_fun,
         flash_error_message,
         log_context
       ) do
    %{current_user: user, uploads: uploads} = socket.assigns
    upload_config = Map.fetch!(uploads, upload_name)
    entry_errors = upload_errors(upload_config, entry)

    cond do
      entry_errors != [] ->
        socket =
          socket
          |> cancel_upload(upload_name, entry.ref)
          |> assign(upload_error_assign, Enum.uniq(entry_errors))

        {:noreply, socket}

      entry.done? ->
        {temp_path, entry} =
          consume_uploaded_entry(socket, entry, fn %{path: path} ->
            {:ok, copy_upload_to_tmp(path, entry, tmp_filename_prefix)}
          end)

        upload = %Plug.Upload{
          path: temp_path,
          filename: entry.client_name,
          content_type: entry.client_type
        }

        socket =
          case update_fun.(user, upload) do
            {:ok, updated_user} ->
              File.rm(temp_path)

              socket
              |> assign(current_user: updated_user)
              |> assign(upload_error_assign, [])

            {:error, error} ->
              Logger.error(
                "#{log_context} upload failed in LiveView: user_id=#{user.id} file=#{entry.client_name} type=#{entry.client_type} reason=#{inspect(error)}"
              )

              File.rm(temp_path)

              socket
              |> assign(upload_error_assign, [:upload_failed])
              |> put_flash(:error, flash_error_message)
          end

        {:noreply, socket}

      true ->
        {:noreply, socket}
    end
  end

  defp copy_upload_to_tmp(path, entry, tmp_filename_prefix) do
    extension = Path.extname(entry.client_name)
    filename = "#{tmp_filename_prefix}-#{entry.uuid}#{extension}"
    temp_path = Path.join(System.tmp_dir!(), filename)

    File.cp!(path, temp_path)

    {temp_path, entry}
  end

  defp profile_cover_url(%{cover_url: cover_url}) when is_binary(cover_url) and cover_url != "",
    do: cover_url

  defp profile_cover_url(_), do: ~p"/images/user-profile-background.jpeg"

  defp assign_profile_data(socket) do
    user = socket.assigns.current_user
    profile_stats = Planning.profile_stats(user)

    visited_country_iso3_codes =
      profile_stats.visited_countries
      |> Enum.map(& &1.iso3)
      |> Enum.reject(&is_nil/1)

    assign(socket,
      visited_countries: profile_stats.visited_countries,
      total_trips: profile_stats.total_trips,
      countries_count: profile_stats.countries,
      days_on_the_road: profile_stats.days_on_the_road,
      visited_country_iso3_codes_json: Jason.encode!(visited_country_iso3_codes),
      visited_cities_json: Jason.encode!(profile_stats.visited_cities),
      extra_visited_cities: Accounts.list_visited_cities(user),
      visited_city_form: new_visited_city_form(user)
    )
  end

  defp new_visited_city_form(user) do
    %VisitedCity{user_id: user.id, city: nil}
    |> Accounts.change_visited_city()
    |> visited_city_form()
  end

  defp visited_city_form(changeset) do
    changeset =
      case changeset.data do
        %VisitedCity{} = visited_city -> %{changeset | data: %{visited_city | city: nil}}
        _ -> changeset
      end

    to_form(changeset, as: :visited_city)
  end
end
