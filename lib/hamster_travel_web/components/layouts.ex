defmodule HamsterTravelWeb.Layouts do
  use HamsterTravelWeb, :html

  import HamsterTravelWeb.Icons.Airplane

  embed_templates "layouts/*"

  def navbar(assigns) do
    ~H"""
    <.container nomargin class="px-6 h-20 flex items-center justify-between">
      <.link href={~p"/"}>
        <h1 class="font-medium dark:text-white">
          Hamster Travel
        </h1>
      </.link>
      <nav class="space-x-6 flex items-center">
        <div class="hidden sm:block">
          <div class="space-x-6 flex items-center">
            <.nav_link to={plans_url()} active={@active_nav == plans_nav_item()}>
              <%= gettext("Plans") %>
            </.nav_link>
            <%= if @current_user do %>
              <.nav_link to={~p"/drafts"} active={@active_nav == drafts_nav_item()}>
                <%= gettext("Drafts") %>
              </.nav_link>
              <.nav_link to={backpacks_url()} active={@active_nav == backpacks_nav_item()}>
                <%= gettext("Backpacks") %>
              </.nav_link>
            <% end %>
          </div>
        </div>
        <%= if @current_user do %>
          <.nav_link to={~p"/profile"}>
            <.avatar size="md" src={@current_user.avatar_url} name={@current_user.name} random_color />
          </.nav_link>
        <% else %>
          <.nav_link to={~p"/users/log_in"}>
            <%= gettext("Log in") %>
          </.nav_link>
        <% end %>
      </nav>
    </.container>
    <div class="sm:hidden">
      <nav
        class="w-full border-t bg-orange-50 dark:bg-zinc-900 dark:border-zinc-800 fixed bottom-0"
        style="z-index: 100"
      >
        <div class="mx-auto px-6 max-w-md h-16 flex items-center justify-around">
          <.mobile_nav
            current_user={@current_user}
            mobile_menu={@mobile_menu}
            active_tab={@active_tab}
            active_nav={@active_nav}
          />
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
        <.mobile_nav_global current_user={@current_user} active_nav={@active_nav} />
        """
    end
  end

  def mobile_nav_plan_tabs(assigns) do
    ~H"""
    <.mobile_nav_link label={gettext("Back")} to={back_url(assigns)} active={false}>
      <.icon name="hero-arrow-left" class="h-6 w-6" />
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
      <.icon name="hero-clipboard-document-list" class="h-6 w-6" />
    </.mobile_nav_link_tab>
    """
  end

  def mobile_nav_global(assigns) do
    ~H"""
    <.mobile_nav_link label={gettext("Homepage")} to={~p"/"} active={@active_nav == home_nav_item()}>
      <.icon name="hero-home" class="w-6 h-6" />
    </.mobile_nav_link>
    <.mobile_nav_link
      label={gettext("Plans")}
      to={plans_url()}
      active={@active_nav == plans_nav_item()}
    >
      <.icon name="hero-book-open" class="w-6 h-6" />
    </.mobile_nav_link>
    <.mobile_nav_link
      :if={@current_user}
      label={gettext("Drafts")}
      to={~p"/drafts"}
      active={@active_nav == drafts_nav_item()}
    >
      <.icon name="hero-light-bulb" class="w-6 h-6" />
    </.mobile_nav_link>
    <.mobile_nav_link
      :if={@current_user}
      label={gettext("Backpacks")}
      to={backpacks_url()}
      active={@active_nav == backpacks_nav_item()}
    >
      <.icon name="hero-briefcase" class="w-6 h-6" />
    </.mobile_nav_link>
    """
  end

  def nav_link(assigns) do
    ~H"""
    <.link navigate={@to} class={"text-sm #{color_classes(assigns)}"}>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  def mobile_nav_link(assigns) do
    ~H"""
    <.link navigate={@to} class={"#{mobile_nav_classes()} #{color_classes(assigns)}"}>
      <%= render_slot(@inner_block) %>
      <.mobile_nav_label label={@label} />
    </.link>
    """
  end

  def mobile_nav_link_tab(assigns) do
    ~H"""
    <.link patch={@to} class={"#{mobile_nav_classes()} #{color_classes(assigns)}"}>
      <%= render_slot(@inner_block) %>
      <.mobile_nav_label label={@label} />
    </.link>
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

  def back_url(assigns) do
    if assigns.active_nav == plans_nav_item() do
      ~p"/plans"
    else
      ~p"/drafts"
    end
  end
end
