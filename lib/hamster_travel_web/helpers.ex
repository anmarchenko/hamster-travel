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

  def plan_url(slug), do: "/plans/#{slug}"
  def plan_url(slug, :itinerary), do: "/plans/#{slug}?tab=itinerary"
  def plan_url(slug, :activities), do: "/plans/#{slug}?tab=activities"
  def plan_url(slug, :catering), do: "/plans/#{slug}?tab=catering"
  def plan_url(slug, :documents), do: "/plans/#{slug}?tab=documents"
  def plan_url(slug, :report), do: "/plans/#{slug}?tab=report"
  def plan_url(slug, :edit), do: "/plans/#{slug}/edit"
  def plan_url(slug, :pdf), do: "/plans/#{slug}/pdf"
  def plan_url(slug, :copy), do: "/plans/#{slug}/copy"
  def plan_url(slug, :delete), do: "/plans/#{slug}/delete"
end
