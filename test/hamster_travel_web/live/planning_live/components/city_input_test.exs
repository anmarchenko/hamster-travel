defmodule HamsterTravelWeb.Planning.CityInputTest do
  use HamsterTravelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HamsterTravel.GeoFixtures

  alias HamsterTravelWeb.Planning.CityInput

  describe "CityInput component" do
    test "renders city input field correctly" do
      # Construct a mock form and form field
      form = %Phoenix.HTML.Form{
        source: %{},
        impl: Phoenix.HTML.FormData.Atom,
        id: "test_form",
        name: "test_form",
        data: %{},
        action: nil,
        hidden: [],
        params: %{},
        errors: [],
        options: [],
        index: nil
      }

      field = %Phoenix.HTML.FormField{
        id: "test_form_city_id",
        name: "test_form[city_id]",
        errors: [],
        field: :city_id,
        form: form,
        value: nil
      }

      html = render_component(CityInput, id: "city-input", field: field, label: "City")

      assert html =~ "City"
      assert html =~ "pc-text-input"
    end
  end
end
