defmodule HamsterTravelWeb.CoreComponents do
  use Phoenix.Component

  alias PetalComponents.Button, as: PetalButton

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
  def backpack_url(slug, :delete), do: "/backpacks/#{slug}/delete"

  attr :class, :string, default: nil
  attr :click, :string, default: nil
  attr :target, :any, default: nil
  attr :color, :string, default: "gray"

  slot(:inner_block, required: true)

  def ht_icon_button(assigns) do
    ~H"""
    <PetalButton.icon_button
      link_type="button"
      size="xs"
      color={@color}
      class={@class}
      phx-click={@click}
      phx-target={@target}
    >
      <%= render_slot(@inner_block) %>
    </PetalButton.icon_button>
    """
  end
end
