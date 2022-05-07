defmodule HamsterTravelWeb.UIComponents do
  @moduledoc """
  Common phoenix components
  """
  use HamsterTravelWeb, :component

  def card(assigns) do
    ~H"""
    <div class="flex flex-row bg-zinc-50 dark:bg-zinc-900 dark:border dark:border-zinc-600 shadow-md rounded-lg hover:shadow-lg hover:bg-white hover:dark:bg-zinc-800">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def secondary_text(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)

    ~H"""
    <p class={"text-zinc-400 dark:text-zinc-500 italic #{@class}"}>
      <%= render_slot(@inner_block) %>
    </p>
    """
  end
end
