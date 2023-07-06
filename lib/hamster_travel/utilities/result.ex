defmodule HamsterTravel.Result do
  @moduledoc """
  Helpers module to work with result values
  """

  def list_or_errors(list) when is_list(list) do
    errors = list |> Enum.filter(fn item -> error?(item) end)

    if Enum.empty?(errors) do
      {:ok, list}
    else
      errors
      |> Enum.reduce({:error, []}, fn {:error, l}, {:error, r} ->
        {:error, Enum.concat(l, r)}
      end)
    end
  end

  defp error?({:error, _}), do: true
  defp error?(_), do: false
end
