defmodule HamsterTravelWeb.CoreComponents do
  use Phoenix.Component, global_prefixes: ~w(x- data-)

  alias PetalComponents.HeroiconsV1, as: Heroicons

  alias HamsterTravelWeb.Router.Helpers, as: Routes

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

  def placeholder_image(id) when is_binary(id) do
    id
    |> :erlang.phash2()
    |> rem(9)
    |> placeholder_image_url()
  end

  def placeholder_image(id) when is_integer(id) do
    id
    |> rem(9)
    |> placeholder_image_url()
  end

  def build_class(classes) do
    classes
    |> Enum.filter(fn class -> class != nil && class != "" end)
    |> Enum.uniq()
    |> Enum.join(" ")
  end

  attr(:icon, :atom, required: true)
  attr(:color, :string, default: "gray")
  attr(:size, :string, default: "xs")
  attr(:class, :string, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:rest, :global, include: ~w(@click x-show))

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
      {@rest}
    >
      <.icon icon={@icon} class={get_icon_button_pic_size_classes(@size)} />
    </button>
    """
  end

  attr(:wide, :boolean, default: false)
  attr(:nomargin, :boolean, default: false)
  attr(:class, :string, default: nil)

  slot(:inner_block, required: true)

  def container(assigns) do
    ~H"""
    <section class={[
      "mx-auto max-w-screen-md",
      container_margins(assigns),
      container_width(assigns),
      @class
    ]}>
      <%= render_slot(@inner_block) %>
    </section>
    """
  end

  defp container_margins(%{nomargin: true}), do: ""
  defp container_margins(_), do: "p-6 mt-6"

  defp container_width(%{wide: true}), do: "xl:max-w-screen-xl 2xl:max-w-screen-2xl"
  defp container_width(_), do: "xl:max-w-screen-lg 2xl:max-w-screen-xl"

  slot(:inner_block, required: true)

  def form_container(assigns) do
    ~H"""
    <div class="flex min-h-full items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div class="w-full max-w-md space-y-8">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  attr(:class, :string, default: nil)

  slot(:inner_block, required: true)

  def card(assigns) do
    ~H"""
    <div class={
      build_class([
        "flex flex-row bg-zinc-50 dark:bg-zinc-900 dark:border dark:border-zinc-600 shadow-md rounded-lg hover:shadow-lg hover:bg-white hover:dark:bg-zinc-800",
        @class
      ])
    }>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:icon, :atom, required: true)
  attr(:rest, :global, default: %{class: "w-5 h-5"})

  defp icon(assigns) do
    ~H"""
    <%= apply(Heroicons.Outline, @icon, [assigns]) %>
    """
  end

  defp get_icon_button_size_classes("xs"), do: "w-9 h-9"
  defp get_icon_button_size_classes("sm"), do: "w-10 h-10"
  defp get_icon_button_size_classes("md"), do: "w-11 h-11"
  defp get_icon_button_size_classes("lg"), do: "w-12 h-12"
  defp get_icon_button_size_classes("xl"), do: "w-14 h-14"

  defp get_icon_button_pic_size_classes("xs"), do: "w-5 h-5"
  defp get_icon_button_pic_size_classes("sm"), do: "w-6 h-6"
  defp get_icon_button_pic_size_classes("md"), do: "w-7 h-7"
  defp get_icon_button_pic_size_classes("lg"), do: "w-8 h-8"
  defp get_icon_button_pic_size_classes("xl"), do: "w-10 h-10"

  defp get_icon_button_color_classes("primary"), do: "text-primary-600 dark:text-primary-500"

  defp get_icon_button_color_classes("white"),
    do: "text-white dark:text-zinc-400 dark:hover:text-zinc-200"

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

  defp placeholder_image_url(number) do
    image_name = "placeholder-#{number}"
    Routes.static_path(HamsterTravelWeb.Endpoint, "/images/#{image_name}.jpg")
  end
end
