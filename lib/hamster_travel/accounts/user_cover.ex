defmodule HamsterTravel.Accounts.UserCover do
  use Waffle.Definition
  use Waffle.Ecto.Definition

  @async false
  @versions [:original, :hero]
  @extension_whitelist ~w(.jpg .jpeg .png .webp)

  def validate({file, _scope}) do
    extension =
      file
      |> file_name()
      |> Path.extname()
      |> String.downcase()

    Enum.member?(@extension_whitelist, extension)
  end

  def transform(:original, _scope), do: :noaction

  def transform(version, _scope) do
    if skip_processing?() do
      :noaction
    else
      case version do
        :hero ->
          {:convert,
           "-auto-orient -thumbnail 2400x960 -colorspace sRGB -quality 95 -sampling-factor 4:4:4 -format jpg",
           :jpg}

        :original ->
          :noaction
      end
    end
  end

  def filename(version, _scope), do: "cover_#{version}"

  def storage_dir(_version, {_file, user}) do
    "uploads/trips/users/#{user.id}/cover"
  end

  def s3_object_headers(:original, {file, _scope}) do
    [
      content_type: MIME.from_path(file_name(file)),
      cache_control: "public, max-age=31536000"
    ]
  end

  def s3_object_headers(_version, _scope) do
    [
      content_type: "image/jpeg",
      cache_control: "public, max-age=31536000"
    ]
  end

  defp file_name(%{file_name: name}) when is_binary(name), do: name
  defp file_name(%{filename: name}) when is_binary(name), do: name
  defp file_name(_file), do: ""

  defp skip_processing? do
    Application.get_env(:hamster_travel, :waffle_skip_processing, false)
  end
end
