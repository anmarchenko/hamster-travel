defmodule HamsterTravelWeb.LayoutView do
  use HamsterTravelWeb, :view

  alias HamsterTravelWeb.{Avatar, Icons}

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  def navbar(assigns) do
    user = %{
      name: "Andrey Marchenko",
      avatar_url: "https://d2fetf4i8a4kn6.cloudfront.net/2014/09/30/11/27/53/591/2014_nizh.png"
    }

    ~H"""
      <div class="mx-auto px-6 max-w-screen-md h-20 flex items-center justify-between">
        <%= live_redirect to: "/" do %>
          <h1 class="font-medium dark:text-white">
            Hamster Travel
          </h1>
        <% end %>
        <nav class="space-x-6 flex items-center">
          <div class="hidden sm:block">
            <div class="space-x-6 flex items-center">
              <.nav_link to="/plans" active={@active_nav == :plans}>
                Планы
              </.nav_link>
              <.nav_link to="/backpacks" active={@active_nav == :backpacks}>
                Рюкзачки
              </.nav_link>
            </div>
          </div>
          <Avatar.small user={user} />
        </nav>
      </div>
      <div class="sm:hidden">
        <nav class="w-full border-t dark:bg-zinc-900 dark:border-zinc-800 fixed bottom-0">
          <div class="mx-auto px-6 max-w-md h-16 flex items-center justify-around">
            <.mobile_nav_link to="/" active={@active_nav == :home}>
              <Icons.home />
              <span class="text-xs text-zinc-600 dark:text-zinc-400">Главная</span>
            </.mobile_nav_link>
            <.mobile_nav_link to="/plans" active={@active_nav == :plans}>
              <Icons.pen />
              <span class="text-xs text-zinc-600 dark:text-zinc-400">Планы</span>
            </.mobile_nav_link>
            <.mobile_nav_link to="/backpacks" active={@active_nav == :backpacks}>
              <Icons.backpack />
              <span class="text-xs text-zinc-600 dark:text-zinc-400">Рюкзачки</span>
            </.mobile_nav_link>
          </div>
        </nav>
      </div>
    """
  end

  def nav_link(assigns) do
    color = color_classes(assigns)

    ~H"""
      <%= live_redirect to: @to, class: "text-sm #{color}" do %>
        <%= render_slot(@inner_block) %>
      <% end %>
    """
  end

  def mobile_nav_link(assigns) do
    color = color_classes(assigns)

    ~H"""
      <%= live_redirect to: @to,
        class: "space-y-1 w-full h-full flex flex-col items-center justify-center #{color}" do %>
        <%= render_slot(@inner_block) %>
      <% end %>
    """
  end

  def color_classes(%{active: true}), do: active_class()
  def color_classes(_), do: inactive_class()

  def active_class, do: "text-indigo-500 dark:text-indigo-400"

  def inactive_class,
    do: "text-zinc-600 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-zinc-50"
end
