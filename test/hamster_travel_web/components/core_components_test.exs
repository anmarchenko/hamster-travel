defmodule HamsterTravelWeb.CoreComponentsTest do
  use HamsterTravelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias HamsterTravelWeb.CoreComponents

  describe "money_input/1" do
    test "uses a decimal mobile keyboard for the amount field" do
      form = %Phoenix.HTML.Form{
        source: %{},
        impl: Phoenix.HTML.FormData.Atom,
        id: "expense",
        name: "expense",
        data: %{},
        action: nil,
        hidden: [],
        params: %{},
        errors: [],
        options: [],
        index: nil
      }

      field = %Phoenix.HTML.FormField{
        id: "expense_price",
        name: "expense[price]",
        errors: [],
        field: :price,
        form: form,
        value: %{"amount" => "12.34", "currency" => "EUR"}
      }

      html =
        render_component(&CoreComponents.money_input/1,
          id: "expense-price",
          field: field,
          label: "Price"
        )

      assert html =~ ~s|id="expense-price_amount"|
      assert html =~ ~s|inputmode="decimal"|
      refute html =~ ~s|inputmode="numeric"|
    end
  end

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
