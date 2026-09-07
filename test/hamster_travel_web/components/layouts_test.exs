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
      assert html =~ "hero-moon"
      assert html =~ "hero-sun"
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
end
