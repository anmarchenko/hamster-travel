defmodule HamsterTravelWeb.LayoutView do
  use HamsterTravelWeb, :view

  import HamsterTravelWeb.Avatar

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  def navbar(assigns) do
    ~H"""
      <div class="mx-auto px-6 max-w-screen-md h-20 flex items-center justify-between">
        <a href="/">
          <h1 class="font-medium dark:text-zinc-400">
            Hamster Travel
          </h1>
        </a>
        <nav class="space-x-6 flex items-center">
          <div class="hidden sm:block">
            <div class="space-x-6 flex items-center">
              <.nav_link to="/plans">
                Путешествия
              </.nav_link>
              <.nav_link to="/backpacks">
                Рюкзачки
              </.nav_link>
            </div>
          </div>
          <.avatar title="Andrey Marchenko" url="https://d2fetf4i8a4kn6.cloudfront.net/2014/09/30/11/27/53/591/2014_nizh.png" />
        </nav>
      </div>
    """
  end

  def nav_link(assigns) do
    ~H"""
      <a
        class="text-sm text-zinc-600 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-zinc-50"
        href={@to}
      >
        <%= render_slot(@inner_block) %>
      </a>
    """
  end
end
