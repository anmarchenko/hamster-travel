defmodule HamsterTravelWeb.LayoutView do
  use HamsterTravelWeb, :view

  import HamsterTravelWeb.UserComponents

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
        <%= live_patch to: "/" do %>
          <h1 class="font-medium dark:text-white">
            Hamster Travel
          </h1>
        <% end %>
        <nav class="space-x-6 flex items-center">
          <div class="hidden sm:block">
            <div class="space-x-6 flex items-center">
              <.nav_link to="/plans" active={@active_nav == :plans}>
                Путешествия
              </.nav_link>
              <.nav_link to="/backpacks" active={@active_nav == :backpacks}>
                Рюкзачки
              </.nav_link>
            </div>
          </div>
          <.avatar user={user} />
        </nav>
      </div>
    """
  end

  def nav_link(assigns) do
    ~H"""
      <%= live_patch to: @to,
        class: "text-sm #{if assigns[:active], do: "text-indigo-500 dark:text-indigo-400", else: "text-zinc-600 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-zinc-50"}" do %>
        <%= render_slot(@inner_block) %>
      <% end %>
    """
  end
end
