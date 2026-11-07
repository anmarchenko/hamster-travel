defmodule HamsterTravel.PhotoUpload do
  @moduledoc false

  @extensions ~w(.jpg .jpeg .png .webp .heic .heif)
  @max_size_mb 25

  def extensions, do: @extensions
  def max_size_mb, do: @max_size_mb
  def max_file_size, do: @max_size_mb * 1_000_000

  def jpeg_transform(options) do
    {:convert,
     fn input, output ->
       [input <> "[0]", "-auto-orient"] ++ options ++ [output]
     end, :jpg}
  end
end
