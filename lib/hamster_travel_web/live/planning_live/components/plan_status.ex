defmodule HamsterTravelWeb.Planning.PlanStatus do
  @moduledoc """
  Renders status row for plan (badge, flags, author)
  """
  use HamsterTravelWeb, :html

  alias HamsterTravelWeb.CoreComponents

  import HamsterTravelWeb.Planning.StatusBadge

  attr(:plan, :map, required: true)
  attr(:class, :string, default: nil)
  attr(:flags_limit, :integer, default: 100)

  def plan_status(assigns) do
    ~H"""
    <.inline class={
      CoreComponents.build_class([
        "gap-3",
        @class
      ])
    }>
      <.status_badge status={@plan.status} />
      <.flag size={24} country="de" />
      <%!-- <%= for country <- Enum.take(@plan.countries, @flags_limit) do %>
        <.flag size={24} country={country} />
      <% end %> --%>
      <.avatar
        size="xs"
        src={@plan.author.avatar_url}
        name={@plan.author.name}
        random_color
        class="!w-6 !h-6"
      />
    </.inline>
    """
  end
end
