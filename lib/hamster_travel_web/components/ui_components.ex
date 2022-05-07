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

  def icon_text(assigns) do
    ~H"""
    <div class="flex flex-row gap-x-2 items-center">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def link(assigns) do
    ~H"""
    <%= live_redirect to: @url, class: "underline text-indigo-500 hover:text-indigo-900 dark:text-indigo-300 dark:hover:text-indigo-100" do %>
      <%= render_slot(@inner_block) %>
    <% end %>
    """
  end

  def external_link(%{link: nil} = assigns) do
    ~H"""

    """
  end

  def external_link(%{link: link} = assigns) do
    uri = URI.parse(link)

    ~H"""
    <UI.link url={@link}>
      <%= uri.host %>
      <br />
    </UI.link>
    """
  end

  def external_links(assigns) do
    ~H"""
    <%= for link <- @links do %>
      <.external_link link={link} />
    <% end %>
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
