defmodule HamsterTravelWeb.LayoutView do
  use HamsterTravelWeb, :view

  import HamsterTravelWeb.Gettext
  import HamsterTravelWeb.Icons.Airplane

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  def navbar(assigns) do
    ~H"""
    <div class="mx-auto max-w-screen-md xl:max-w-screen-lg 2xl:max-w-screen-xl px-6 h-20 flex items-center justify-between">
      <%= live_redirect to: "/" do %>
        <h1 class="font-medium dark:text-white">
          Hamster Travel
        </h1>
      <% end %>
      <nav class="space-x-6 flex items-center">
        <div class="hidden sm:block">
          <div class="space-x-6 flex items-center">
            <.nav_link to="/plans" active={@active_nav == :plans}>
              <%= gettext("Plans") %>
            </.nav_link>
            <.nav_link to="/drafts" active={@active_nav == :drafts}>
              <%= gettext("Drafts") %>
            </.nav_link>
            <.nav_link to="/backpacks" active={@active_nav == :backpacks}>
              <%= gettext("Backpacks") %>
            </.nav_link>
          </div>
        </div>
        <%= if @current_user do %>
          <.avatar size="md" src={@current_user.avatar_url} name={@current_user.name} random_color />
        <% else %>
          <.nav_link to="/users/log_in">
            <%= gettext("Log in") %>
          </.nav_link>
        <% end %>
      </nav>
    </div>
    <div class="sm:hidden">
      <nav class="w-full border-t bg-orange-50 dark:bg-zinc-900 dark:border-zinc-800 fixed bottom-0">
        <div class="mx-auto px-6 max-w-md h-16 flex items-center justify-around">
          <.mobile_nav mobile_menu={@mobile_menu} active_tab={@active_tab} active_nav={@active_nav} />
        </div>
      </nav>
    </div>
    """
  end

  def mobile_nav(assigns) do
    case assigns.mobile_menu do
      :plan_tabs ->
        ~H"""
        <.mobile_nav_plan_tabs active_tab={@active_tab} active_nav={@active_nav} />
        """

      nil ->
        ~H"""
        <.mobile_nav_global active_nav={@active_nav} />
        """
    end
  end

  def mobile_nav_plan_tabs(assigns) do
    back_url =
      if assigns.active_nav == :plans do
        "/plans"
      else
        "/drafts"
      end

    ~H"""
    <.mobile_nav_link label={gettext("Back")} to={back_url} active={false}>
      <Heroicons.Outline.arrow_left />
    </.mobile_nav_link>
    <.mobile_nav_link_tab
      label={gettext("Transfers")}
      to="?tab=itinerary"
      active={@active_tab == "itinerary"}
    >
      <.airplane class="h-6 w-6" />
    </.mobile_nav_link_tab>
    <.mobile_nav_link_tab
      label={gettext("Activities")}
      to="?tab=activities"
      active={@active_tab == "activities"}
    >
      <Heroicons.Outline.clipboard_list />
    </.mobile_nav_link_tab>
    """
  end

  def mobile_nav_global(assigns) do
    ~H"""
    <.mobile_nav_link label={gettext("Homepage")} to="/" active={@active_nav == :home}>
      <Heroicons.Outline.home />
    </.mobile_nav_link>
    <.mobile_nav_link label={gettext("Plans")} to="/plans" active={@active_nav == :plans}>
      <Heroicons.Outline.book_open />
    </.mobile_nav_link>
    <.mobile_nav_link label={gettext("Drafts")} to="/drafts" active={@active_nav == :drafts}>
      <Heroicons.Outline.light_bulb />
    </.mobile_nav_link>
    <.mobile_nav_link label={gettext("Backpacks")} to="/backpacks" active={@active_nav == :backpacks}>
      <Heroicons.Outline.briefcase />
    </.mobile_nav_link>
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
    <%= live_redirect to: @to, class: "#{mobile_nav_classes()} #{color}" do %>
      <%= render_slot(@inner_block) %>
      <.mobile_nav_label label={@label} />
    <% end %>
    """
  end

  def mobile_nav_link_tab(assigns) do
    color = color_classes(assigns)

    ~H"""
    <%= live_patch to: @to, class: "#{mobile_nav_classes()} #{color}" do %>
      <%= render_slot(@inner_block) %>
      <.mobile_nav_label label={@label} />
    <% end %>
    """
  end

  def mobile_nav_label(assigns) do
    ~H"""
    <span class="text-xs text-zinc-600 dark:text-zinc-400"><%= @label %></span>
    """
  end

  def mobile_nav_classes, do: "space-y-1 w-full h-full flex flex-col items-center justify-center"

  def color_classes(%{active: true}), do: active_class()
  def color_classes(_), do: inactive_class()

  def active_class, do: "text-indigo-500 dark:text-indigo-400"

  def inactive_class,
    do: "text-zinc-600 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-zinc-50"
end
