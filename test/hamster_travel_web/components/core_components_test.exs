defmodule HamsterTravelWeb.CoreComponentsTest do
  use HamsterTravelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias HamsterTravelWeb.CoreComponents

  describe "formatted_text/1 sanitization" do
    test "strips unsafe tags and attributes" do
      input =
        ~s|<p>Safe <strong>bold</strong></p><img src="x" onerror="alert(1)"><script>alert(1)</script>|

      html = render_component(&CoreComponents.formatted_text/1, text: input)

      assert html =~ "<strong>bold</strong>"
      refute html =~ "<script"
      refute html =~ "onerror"
    end

    test "preserves safe formatting tags" do
      input = ~s|<p>Line<br><strong>Bold</strong> and <em>emphasis</em></p>|

      html = render_component(&CoreComponents.formatted_text/1, text: input)

      assert html =~ "<p>"
      assert html =~ "<br"
      assert html =~ "<strong>Bold</strong>"
      assert html =~ "<em>emphasis</em>"
    end

    test "preserves safe links" do
      input = ~s|<p><a href="https://example.com">Visit</a></p>|

      html = render_component(&CoreComponents.formatted_text/1, text: input)

      assert html =~ ~s|<a href="https://example.com">Visit</a>|
    end
  end
end
