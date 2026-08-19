defmodule HamsterTravelWeb.Planning.ShowTripTabs do
  @moduledoc false

  alias Phoenix.LiveView.JS

  @tabs ~w(itinerary activities budget notes)
  @desktop_active_classes "pc-tab__underline--is-active pc-tab__underline--with-underline-and-is-active"
  @desktop_inactive_classes "pc-tab__underline--is-not-active pc-tab__underline--with-underline-and-is-not-active"
  @mobile_active_classes "text-indigo-500 dark:text-indigo-400"
  @mobile_inactive_classes "text-zinc-600 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-zinc-50"

  @spec tabs() :: [String.t()]
  def tabs, do: @tabs

  @spec show(JS.t(), String.t()) :: JS.t()
  def show(js \\ %JS{}, tab) when tab in @tabs do
    js
    |> JS.add_class("hidden", to: "[data-trip-tab-panel]")
    |> JS.remove_class("hidden", to: panel_selector(tab))
    |> update_controls(tab)
    |> JS.push("show_trip_tab", value: %{tab: tab})
  end

  defp update_controls(js, active_tab) do
    Enum.reduce(@tabs, js, fn tab, js ->
      selected? = tab == active_tab

      js
      |> JS.set_attribute({"aria-selected", to_string(selected?)}, to: control_selector(tab))
      |> update_desktop_classes(tab, selected?)
      |> update_mobile_classes(tab, selected?)
    end)
  end

  defp update_desktop_classes(js, tab, true) do
    js
    |> JS.remove_class(@desktop_inactive_classes, to: desktop_control_selector(tab))
    |> JS.add_class(@desktop_active_classes, to: desktop_control_selector(tab))
  end

  defp update_desktop_classes(js, tab, false) do
    js
    |> JS.remove_class(@desktop_active_classes, to: desktop_control_selector(tab))
    |> JS.add_class(@desktop_inactive_classes, to: desktop_control_selector(tab))
  end

  defp update_mobile_classes(js, tab, true) do
    js
    |> JS.remove_class(@mobile_inactive_classes, to: mobile_control_selector(tab))
    |> JS.add_class(@mobile_active_classes, to: mobile_control_selector(tab))
  end

  defp update_mobile_classes(js, tab, false) do
    js
    |> JS.remove_class(@mobile_active_classes, to: mobile_control_selector(tab))
    |> JS.add_class(@mobile_inactive_classes, to: mobile_control_selector(tab))
  end

  defp panel_selector(tab), do: "#trip-tab-panel-#{tab}"
  defp control_selector(tab), do: ~s([data-trip-tab="#{tab}"])

  defp desktop_control_selector(tab),
    do: ~s([data-trip-tab-kind="desktop"][data-trip-tab="#{tab}"])

  defp mobile_control_selector(tab), do: ~s([data-trip-tab-kind="mobile"][data-trip-tab="#{tab}"])
end
