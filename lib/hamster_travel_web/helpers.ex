defmodule HamsterTravelWeb.Helpers do
  def class_list(classes) do
    classes
    |> Enum.filter(fn {_, active} -> active end)
    |> Enum.map(fn {cl, _} -> cl end)
    |> Enum.join(" ")
  end
end
