defmodule HamsterTravelWeb.Planning.Trips.StatusRow do
  @moduledoc """
  Renders status row for plan (badge, flags, author)
  """
  use HamsterTravelWeb, :html

  alias HamsterTravelWeb.CoreComponents

  import HamsterTravelWeb.Planning.Trips.StatusBadge

  attr(:trip, :map, required: true)
  attr(:class, :string, default: nil)
  attr(:flags_limit, :integer, default: 100)

  def status_row(assigns) do
    ~H"""
    <.inline class={
      CoreComponents.build_class([
        "gap-3",
        @class
      ])
    }>
      <.status_badge status={@trip.status} />
      <.flag size={24} country="de" />
      <%!-- <%= for country <- Enum.take(@plan.countries, @flags_limit) do %>
        <.flag size={24} country={country} />
      <% end %> --%>
      <.avatar
        size="xs"
        src={@trip.author.avatar_url}
        name={@trip.author.name}
        random_color
        class="!w-6 !h-6"
      />
    </.inline>
    """
  end
end
