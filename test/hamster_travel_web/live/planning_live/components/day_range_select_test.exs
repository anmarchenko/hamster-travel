defmodule HamsterTravelWeb.Planning.DayRangeSelectTest do
  use HamsterTravelWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias HamsterTravelWeb.Planning.DayRangeSelect

  describe "DayRangeSelect component" do
    test "renders day range select component correctly" do
      # Construct a mock form and form fields
      form = %Phoenix.HTML.Form{
        source: %{},
        impl: Phoenix.HTML.FormData.Map,
        id: "test_form",
        name: "test_form",
        data: %{"start_day" => 0, "end_day" => 3},
        action: nil,
        hidden: [],
        params: %{},
        errors: [],
        options: [],
        index: nil
      }

      start_day_field = %Phoenix.HTML.FormField{
        id: "test_form_start_day",
        name: "test_form[start_day]",
        errors: [],
        field: :start_day,
        form: form,
        value: 0
      }

      end_day_field = %Phoenix.HTML.FormField{
        id: "test_form_end_day",
        name: "test_form[end_day]",
        errors: [],
        field: :end_day,
        form: form,
        value: 3
      }

      html =
        render_component(DayRangeSelect,
          id: "day-range-select",
          start_day_field: start_day_field,
          end_day_field: end_day_field,
          label: "Select Day Range",
          duration: 5,
          start_date: ~D[2023-01-01]
        )

      assert html =~ "day-range-select-live-component"
      assert html =~ "Select Day Range"
      assert html =~ "2023-01-01"
      assert html =~ "01.01"
      assert html =~ "04.01"
    end
  end
end
