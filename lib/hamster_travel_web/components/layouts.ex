defmodule HamsterTravelWeb.Layouts do
  use HamsterTravelWeb, :html

  import HamsterTravelWeb.Icons.Airplane

  alias HamsterTravelWeb.Planning.ShowTripTabs

  embed_templates "layouts/*"

  def navbar(assigns) do
    ~H"""
    <.container nomargin full class="px-6 h-20 flex items-center justify-between">
      <.link href={~p"/"}>
        <h1 class="font-medium dark:text-white">
          Hamster Travel
        </h1>
      </.link>
      <nav class="flex items-center gap-6">
        <div class="hidden sm:block">
          <div class="flex items-center gap-6">
            <%= if @current_user do %>
              <.nav_link to={plans_url()} active={@active_nav == plans_nav_item()}>
                {gettext("Plans")}
              </.nav_link>
              <.nav_link to={~p"/drafts"} active={@active_nav == drafts_nav_item()}>
                {gettext("Drafts")}
              </.nav_link>
              <.nav_link to={backpacks_url()} active={@active_nav == backpacks_nav_item()}>
                {gettext("Backpacks")}
              </.nav_link>
            <% end %>
          </div>
        </div>
        <div class="flex items-center gap-3.5">
          <button
            type="button"
            data-theme-toggle
            data-dark-label={gettext("Switch to dark mode")}
            data-light-label={gettext("Switch to light mode")}
            aria-label={gettext("Toggle color mode")}
            aria-pressed="false"
            class="inline-flex h-9 w-9 items-center justify-center rounded-full text-zinc-600 transition-colors hover:bg-orange-100 hover:text-zinc-900 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500 focus-visible:ring-offset-2 focus-visible:ring-offset-orange-50 dark:text-zinc-300 dark:hover:bg-zinc-800 dark:hover:text-white dark:focus-visible:ring-offset-zinc-900"
          >
            <.icon name="hero-moon" class="hidden h-5 w-5 dark:inline-block" />
            <.icon name="hero-sun" class="h-5 w-5 dark:hidden" />
          </button>
          <% locale = current_locale(@current_user) %>
          <.link
            href={~p"/users/locale?locale=#{other_locale(locale)}"}
            method="post"
            data-locale-switch
            data-current-locale={locale}
            data-target-locale={other_locale(locale)}
            aria-label={locale_switch_label(locale)}
            title={locale_switch_label(locale)}
            class="inline-flex h-9 w-9 items-center justify-center rounded-full text-xs font-semibold uppercase text-zinc-600 transition-colors hover:bg-orange-100 hover:text-zinc-900 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500 focus-visible:ring-offset-2 focus-visible:ring-offset-orange-50 dark:text-zinc-300 dark:hover:bg-zinc-800 dark:hover:text-white dark:focus-visible:ring-offset-zinc-900"
          >
            {locale}
          </.link>
        </div>
        <%= if @current_user do %>
          <.nav_link to={~p"/profile"}>
            <.avatar size="md" src={@current_user.avatar_url} name={@current_user.name} random_color />
          </.nav_link>
        <% else %>
          <.nav_link to={~p"/users/log_in"}>
            {gettext("Log in")}
          </.nav_link>
        <% end %>
      </nav>
    </.container>
    <div class="sm:hidden">
      <nav class="w-full border-t bg-orange-50 dark:bg-zinc-900 dark:border-zinc-800 fixed bottom-0 z-40">
        <div class="mx-auto px-6 max-w-md h-16 flex items-center justify-around">
          <.mobile_nav
            current_user={@current_user}
            mobile_menu={@mobile_menu}
            active_tab={@active_tab}
            active_nav={@active_nav}
            return_to={@return_to}
            trip_slug={@trip_slug}
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
        <.mobile_nav_plan_tabs
          active_tab={@active_tab}
          active_nav={@active_nav}
          return_to={@return_to}
          trip_slug={@trip_slug}
        />
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
    <div class="contents" role="tablist" aria-label={gettext("Trip plan")}>
      <.mobile_nav_link_tab
        label={gettext("Transfers")}
        tab="itinerary"
        active={@active_tab == "itinerary"}
      >
        <.airplane class="h-6 w-6" />
      </.mobile_nav_link_tab>
      <.mobile_nav_link_tab
        label={gettext("Activities")}
        tab="activities"
        active={@active_tab == "activities"}
      >
        <.icon name="hero-ticket" class="h-6 w-6" />
      </.mobile_nav_link_tab>
      <.mobile_nav_link_tab label={gettext("Budget")} tab="budget" active={@active_tab == "budget"}>
        <.icon name="hero-banknotes" class="h-6 w-6" />
      </.mobile_nav_link_tab>
      <.mobile_nav_link_tab label={gettext("Notes")} tab="notes" active={@active_tab == "notes"}>
        <.icon name="hero-document-text" class="h-6 w-6" />
      </.mobile_nav_link_tab>
    </div>
    """
  end

  def mobile_nav_global(assigns) do
    ~H"""
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
      {render_slot(@inner_block)}
    </.link>
    """
  end

  def mobile_nav_link(assigns) do
    ~H"""
    <.link navigate={@to} class={"#{mobile_nav_classes()} #{color_classes(assigns)}"}>
      {render_slot(@inner_block)} <.mobile_nav_label label={@label} />
    </.link>
    """
  end

  def mobile_nav_link_tab(assigns) do
    ~H"""
    <button
      id={"mobile-trip-tab-#{@tab}"}
      type="button"
      role="tab"
      aria-selected={to_string(@active)}
      aria-controls={"trip-tab-panel-#{@tab}"}
      data-trip-tab={@tab}
      data-trip-tab-kind="mobile"
      data-offline-local
      phx-click={ShowTripTabs.show(@tab)}
      class={"#{mobile_nav_classes()} #{color_classes(assigns)}"}
    >
      {render_slot(@inner_block)} <.mobile_nav_label label={@label} />
    </button>
    """
  end

  def mobile_nav_label(assigns) do
    ~H"""
    <span class="text-xs text-zinc-600 dark:text-zinc-400">{@label}</span>
    """
  end

  def mobile_nav_classes, do: "space-y-1 w-full h-full flex flex-col items-center justify-center"

  def color_classes(%{active: true}), do: active_class()
  def color_classes(_), do: inactive_class()

  def active_class, do: "text-indigo-500 dark:text-indigo-400"

  def inactive_class,
    do: "text-zinc-600 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-zinc-50"

  defp current_locale(%{locale: locale}) when locale in ["en", "ru"], do: locale

  defp current_locale(_current_user) do
    case Gettext.get_locale(HamsterTravelWeb.Gettext) do
      locale when locale in ["en", "ru"] -> locale
      _locale -> "en"
    end
  end

  defp other_locale("ru"), do: "en"
  defp other_locale(_locale), do: "ru"

  defp locale_switch_label("ru"), do: gettext("Switch to English")
  defp locale_switch_label(_locale), do: gettext("Switch to Russian")

  def back_url(assigns) do
    cond do
      is_binary(assigns[:return_to]) ->
        assigns.return_to

      assigns.active_nav == plans_nav_item() ->
        ~p"/plans"

      true ->
        ~p"/drafts"
    end
  end
end
