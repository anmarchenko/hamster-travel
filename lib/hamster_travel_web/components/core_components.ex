defmodule HamsterTravelWeb.CoreComponents do
  use Phoenix.Component, global_prefixes: ~w(x- data-)

  import PetalComponents.Icon

  alias HamsterTravelWeb.Router.Helpers, as: Routes

  def plan_url(slug), do: "/plans/#{slug}"
  def plan_url(slug, :show), do: plan_url(slug)
  def plan_url(slug, :itinerary), do: "/plans/#{slug}?tab=itinerary"
  def plan_url(slug, :activities), do: "/plans/#{slug}?tab=activities"
  def plan_url(slug, _), do: plan_url(slug)

  def backpack_url(slug), do: "/backpacks/#{slug}"
  def backpack_url(slug, :show), do: backpack_url(slug)
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

  attr(:wide, :boolean, default: false)
  attr(:nomargin, :boolean, default: false)
  attr(:class, :string, default: nil)

  slot(:inner_block, required: true)

  def container(assigns) do
    ~H"""
    <section class={
      build_class([
        "mx-auto max-w-screen-md lg:max-w-screen-lg xl:max-w-screen-lg",
        container_margins(assigns),
        container_width(assigns),
        @class
      ])
    }>
      <%= render_slot(@inner_block) %>
    </section>
    """
  end

  defp container_margins(%{nomargin: true}), do: ""
  defp container_margins(_), do: "p-6 mt-6"

  defp container_width(%{wide: true}), do: "2xl:max-w-screen-2xl"
  defp container_width(_), do: "2xl:max-w-screen-xl"

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

  attr(:label, :string, required: true)
  attr(:icon, :atom, required: true)
  attr(:style, :atom, default: :solid)
  attr(:class, :string, default: "w-5 h-5")
  attr(:rest, :global)

  def icon_text(assigns) do
    ~H"""
    <.icon name={@icon} outline={@style == :outline} solid={@style == :solid} class={@class} {@rest} />
    <span class="hidden sm:inline ml-2">
      <%= @label %>
    </span>
    """
  end

  attr(:link, :string, required: true)

  def external_link(assigns) do
    ~H"""
    <.link
      href={@link}
      class="underline text-indigo-500 hover:text-indigo-900 dark:text-indigo-300 dark:hover:text-indigo-100"
    >
      <%= URI.parse(@link).host %>
    </.link>
    """
  end

  attr(:links, :list, required: true)

  def external_links(assigns) do
    ~H"""
    <%= for link <- @links do %>
      <.external_link link={link} />
    <% end %>
    """
  end

  attr(:country, :string, required: true)
  attr(:size, :integer, required: true, values: [16, 24, 32, 48])
  attr(:class, :string, default: "")

  def flag(assigns) do
    ~H"""
    <img
      class={@class}
      src={Routes.static_path(HamsterTravelWeb.Endpoint, "/images/flags/#{@size}/#{@country}.png")}
      alt={"Country #{@country}"}
      style={"width: #{@size}px;  height: #{@size}px"}
    />
    """
  end

  attr(:class, :string, default: nil)
  slot(:inner_block, required: true)

  def header(assigns) do
    ~H"""
    <h1 class={build_class(["text-xl lg:text-2xl font-semibold", @class])}>
      <%= render_slot(@inner_block) %>
    </h1>
    """
  end

  attr(:tag, :string, default: "p")
  attr(:italic, :boolean, default: true)
  attr(:class, :string, default: nil)
  slot(:inner_block, required: true)

  def secondary(%{tag: "div"} = assigns) do
    ~H"""
    <div class={build_class([secondary_component_class(assigns), @class])}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def secondary(%{tag: "p"} = assigns) do
    ~H"""
    <p class={build_class([secondary_component_class(assigns), @class])}>
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  defp secondary_component_class(assigns) do
    "text-zinc-400 #{secondary_italic_class(assigns)}"
  end

  defp secondary_italic_class(%{italic: true}), do: "italic"
  defp secondary_italic_class(_), do: ""

  attr(:wrap, :boolean, default: false)
  attr(:class, :string, default: nil)
  slot(:inner_block, required: true)

  def inline(assigns) do
    ~H"""
    <div class={build_class([inline_component_class(assigns), @class])}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp inline_component_class(assigns) do
    "flex flex-row gap-2 items-center block #{inline_wrap(assigns)}"
  end

  defp inline_wrap(%{wrap: true}), do: "flex-wrap"
  defp inline_wrap(_), do: ""

  defp placeholder_image_url(number) do
    image_name = "placeholder-#{number}"
    Routes.static_path(HamsterTravelWeb.Endpoint, "/images/#{image_name}.jpg")
  end
end
