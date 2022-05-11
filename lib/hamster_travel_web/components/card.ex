defmodule HamsterTravelWeb.Card do
  @moduledoc """
  Renders card
  """
  use HamsterTravelWeb, :component
  import PhxComponentHelpers

  @default_class "flex flex-row bg-zinc-50 dark:bg-zinc-900 dark:border dark:border-zinc-600 shadow-md rounded-lg hover:shadow-lg hover:bg-white hover:dark:bg-zinc-800"

  def card(assigns) do
    assigns
    |> set_attributes([], required: [:inner_block])
    |> extend_class(@default_class)
    |> render()
  end

  defp render(assigns) do
    ~H"""
    <div {@heex_class}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
