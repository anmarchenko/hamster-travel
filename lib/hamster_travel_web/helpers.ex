defmodule HamsterTravelWeb.Helpers do
  @moduledoc """
  style and classes helpers
  """
  def class_list(classes) do
    classes
    |> Enum.filter(fn {_, active} -> active end)
    |> Enum.map(fn {cl, _} -> cl end)
    |> Enum.join(" ")
  end

  def standard_container, do: "mx-auto max-w-screen-md xl:max-w-screen-lg 2xl:max-w-screen-xl"
  def wide_container, do: "mx-auto max-w-screen-md xl:max-w-screen-xl 2xl:max-w-screen-2xl"

  def card_styles,
    do:
      "bg-zinc-50 dark:bg-zinc-900 dark:border dark:border-zinc-600 shadow-md rounded-lg hover:shadow-lg hover:bg-white hover:dark:bg-zinc-800"
end
