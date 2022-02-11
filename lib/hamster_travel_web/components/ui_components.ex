defmodule HamsterTravelWeb.UIComponents do
  @moduledoc """
  Common phoenix components
  """
  use HamsterTravelWeb, :component

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

  def external_link(assigns) do
    uri = URI.parse(assigns[:link])

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

  def tabs(assigns) do
    classes = assigns[:class] || ""

    ~H"""
      <div class={"flex border-b border-gray-200 dark:border-gray-700 gap-x-4 #{classes}"}>
        <%= render_slot(@inner_block) %>
      </div>
    """
  end

  def tab(%{active: active} = assigns) do
    classes =
      class_list([
        {
          "flex items-center h-10 px-2 py-2 -mb-px text-center bg-transparent",
          true
        },
        {
          "border-b-2 -px-1 whitespace-nowrap focus:outline-none",
          true
        },
        {
          "text-gray-700 border-transparent dark:text-white cursor-base hover:border-gray-400",
          !active
        },
        {"text-indigo-600 border-indigo-500 dark:border-indigo-400 dark:text-indigo-300", active}
      ])

    ~H"""
      <%= live_patch to: @url, class: classes do %>
        <%= render_slot(@inner_block) %>
      <% end %>
    """
  end

  def secondary_text(assigns) do
    ~H"""
      <p class="text-zinc-400 dark:text-zinc-600 italic">
        <%= render_slot(@inner_block) %>
      </p>
    """
  end
end
