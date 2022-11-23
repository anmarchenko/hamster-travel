defmodule HamsterTravelWeb.CoreComponents do
  use Phoenix.Component

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

  def backpack_url(slug), do: "/backpacks/#{slug}"
  def backpack_url(slug, :edit), do: "/backpacks/#{slug}/edit"

  def build_class(classes) do
    classes
    |> Enum.filter(fn class -> class != nil && class != "" end)
    |> Enum.uniq()
    |> Enum.join(" ")
  end

  attr :class, :string, default: nil
  attr :"phx-click", :string, default: nil
  attr :"phx-target", :any, default: nil
  attr :disabled, :boolean, default: false
  attr :color, :string, default: "gray"
  attr :size, :string, default: "xs"

  slot(:inner_block, required: true)

  def ht_icon_button(assigns) do
    ~H"""
    <button
      class={
        build_class([
          "rounded-full p-2 inline-block",
          get_disabled_classes(@disabled),
          get_icon_button_size_classes(@size),
          get_icon_button_color_classes(@color),
          get_icon_button_background_color_classes(@color),
          @class
        ])
      }
      {assigns_to_attributes(assigns, [:class, :color, :size])}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp get_icon_button_size_classes("xs"), do: "w-9 h-9"
  defp get_icon_button_size_classes("sm"), do: "w-10 h-10"
  defp get_icon_button_size_classes("md"), do: "w-11 h-11"
  defp get_icon_button_size_classes("lg"), do: "w-12 h-12"
  defp get_icon_button_size_classes("xl"), do: "w-14 h-14"

  defp get_icon_button_color_classes("primary"), do: "text-primary-600 dark:text-primary-500"

  defp get_icon_button_color_classes("white"),
    do: "text-white dark:text-white-400 dark:hover:text-white-900"

  defp get_icon_button_color_classes("secondary"),
    do: "text-secondary-600 dark:text-secondary-500"

  defp get_icon_button_color_classes("gray"),
    do: "text-gray-400 dark:text-gray-500 hover:text-gray-600 hover:dark:text-gray-300"

  defp get_icon_button_color_classes("info"), do: "text-blue-600 dark:text-blue-500"
  defp get_icon_button_color_classes("success"), do: "text-green-600 dark:text-green-500"
  defp get_icon_button_color_classes("warning"), do: "text-yellow-600 dark:text-yellow-500"
  defp get_icon_button_color_classes("danger"), do: "text-red-600 dark:text-red-500"

  defp get_icon_button_background_color_classes("primary"),
    do: "hover:bg-primary-50 dark:hover:bg-gray-800"

  defp get_icon_button_background_color_classes("white"),
    do: "hover:bg-primary-600 dark:hover:bg-primary-800"

  defp get_icon_button_background_color_classes("secondary"),
    do: "hover:bg-secondary-50 dark:hover:bg-gray-800"

  defp get_icon_button_background_color_classes("gray"),
    do: "hover:bg-gray-100 dark:hover:bg-gray-800"

  defp get_icon_button_background_color_classes("info"),
    do: "hover:bg-blue-50 dark:hover:bg-gray-800"

  defp get_icon_button_background_color_classes("success"),
    do: "hover:bg-green-50 dark:hover:bg-gray-800"

  defp get_icon_button_background_color_classes("warning"),
    do: "hover:bg-yellow-50 dark:hover:bg-gray-800"

  defp get_icon_button_background_color_classes("danger"),
    do: "hover:bg-red-50 dark:hover:bg-gray-800"

  defp get_disabled_classes(true), do: "disabled cursor-not-allowed opacity-50"
  defp get_disabled_classes(false), do: ""
end
