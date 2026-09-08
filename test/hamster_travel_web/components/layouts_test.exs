defmodule HamsterTravelWeb.LayoutsTest do
  use HamsterTravelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias HamsterTravelWeb.Layouts

  describe "navigation theme switcher" do
    test "renders an accessible theme toggle" do
      html = render_app_layout()

      assert html =~ "data-theme-toggle"
      assert html =~ ~s(data-dark-label="Switch to dark mode")
      assert html =~ ~s(data-light-label="Switch to light mode")
      assert html =~ ~s(aria-pressed="false")
      assert html =~ ~s(class="hero-moon hidden h-5 w-5 dark:inline-block")
      assert html =~ ~s(class="hero-sun h-5 w-5 dark:hidden")
      assert length(:binary.matches(html, ~s(class="flex items-center gap-6"))) == 2
      assert html =~ ~s(class="flex items-center gap-3.5")
    end
  end

  describe "navigation locale switcher" do
    test "does not render for an unauthenticated visitor" do
      html = render_app_layout()

      refute html =~ "data-locale-switch"
    end

    test "renders a control that switches from English to Russian" do
      html = render_app_layout(current_user: user_with_locale("en"))

      assert html =~ "data-locale-switch"
      assert html =~ ~s(data-current-locale="en")
      assert html =~ ~s(data-target-locale="ru")
      assert html =~ ~s(aria-label="Switch to Russian")
      assert html =~ ~s(phx-click="switch_locale")
      assert html =~ ~s(phx-value-locale="ru")
      assert html =~ ~r/data-locale-switch[^>]*>\s*en\s*<\/button>/
    end

    test "renders a control that switches from Russian to English" do
      html =
        Gettext.with_locale(HamsterTravelWeb.Gettext, "ru", fn ->
          render_app_layout(current_user: user_with_locale("ru"))
        end)

      assert html =~ ~s(data-current-locale="ru")
      assert html =~ ~s(data-target-locale="en")
      assert html =~ ~s(aria-label="Переключить на английский")
      assert html =~ ~s(phx-value-locale="en")
      assert html =~ ~r/data-locale-switch[^>]*>\s*ru\s*<\/button>/
    end
  end

  describe "offline edit boundaries" do
    test "locks the complete main content by default" do
      html = render_app_layout()

      assert html =~ ~s(id="offline-read-only-root")
      assert html =~ ~s(phx-hook="OfflineReadOnly")
      assert html =~ ~r/<main[^>]*data-offline-lock/
      refute html =~ "data-offline-local"

      {offline_notice_position, _length} = :binary.match(html, ~s(id="disconnected"))
      {locked_main_position, _length} = :binary.match(html, ~s(id="offline-read-only-root"))

      assert offline_notice_position < locked_main_position
    end

    test "leaves main unlocked only for pages with local offline tabs" do
      html = render_app_layout(offline_local_tabs: true)

      assert html =~ ~s(id="offline-read-only-root")
      assert html =~ ~s(phx-hook="OfflineReadOnly")
      refute html =~ ~r/<main[^>]*data-offline-lock/
    end
  end

  defp render_app_layout(extra_assigns \\ []) do
    assigns =
      Keyword.merge(
        [
          inner_content: "Page content",
          current_user: nil,
          flash: %{}
        ],
        extra_assigns
      )

    render_component(&Layouts.app/1, assigns)
  end

  defp user_with_locale(locale) do
    %{avatar_url: nil, locale: locale, name: "User"}
  end
end
