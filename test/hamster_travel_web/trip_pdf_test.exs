defmodule HamsterTravelWeb.TripPdfTest do
  use HamsterTravel.DataCase

  alias HamsterTravel.Geo
  alias HamsterTravel.Planning
  alias HamsterTravelWeb.Gettext, as: HTGettext
  alias HamsterTravelWeb.TripPdf

  import HamsterTravel.GeoFixtures
  import HamsterTravel.PlanningFixtures

  defmodule CaptureRenderer do
    @behaviour HamsterTravelWeb.TripPdf.Renderer

    @impl true
    def render(html, opts) do
      send(self(), {:capture_renderer_called, html, opts})
      {:ok, "<<pdf-binary>>"}
    end
  end

  defmodule ErrorRenderer do
    @behaviour HamsterTravelWeb.TripPdf.Renderer

    @impl true
    def render(_html, _opts), do: {:error, :renderer_failed}
  end

  setup do
    Gettext.put_locale(HTGettext, "en")
    :ok
  end

  describe "to_html/2" do
    test "shows known trip date range in header" do
      trip = trip_fixture(%{start_date: ~D[2026-02-01], end_date: ~D[2026-02-10]})

      html = trip_html(trip)

      assert html =~ "01.02.2026 - 10.02.2026"
    end

    test "shows duration only when dates are unknown" do
      trip = trip_fixture(%{dates_unknown: true, duration: 4})

      html = trip_html(trip)

      assert html =~ "4 days"
      refute html =~ "01.02.2026 - 10.02.2026"
    end

    test "does not render whole-trip notes section when there are no unassigned notes" do
      trip = trip_fixture(%{dates_unknown: true, duration: 3})

      html = trip_html(trip)

      refute html =~ "Whole-trip notes"
    end

    test "renders whole-trip notes section when unassigned notes exist" do
      trip = trip_fixture(%{dates_unknown: true, duration: 3})
      note_token = "WHOLE_TRIP_NOTE_TOKEN_2f554b6a"

      {:ok, _note} =
        Planning.create_note(trip, %{
          title: "General notes",
          text: "<p>#{note_token}</p>"
        })

      html = trip_html(trip)

      assert html =~ "Whole-trip notes"
      assert html =~ note_token
    end

    test "preserves rich-text formatting and strips youtube content" do
      trip = trip_fixture(%{dates_unknown: true, duration: 3})

      {:ok, _note} =
        Planning.create_note(trip, %{
          title: "Food",
          text: """
          <p><strong>Bold</strong> and <em>italic</em></p>
          <ul><li>Item one</li></ul>
          <p><a href="https://example.com/menu">Menu</a></p>
          <p>https://youtu.be/video-token</p>
          <iframe src="https://www.youtube.com/embed/some-video"></iframe>
          """
        })

      html = trip_html(trip)

      assert html =~ "<strong>Bold</strong>"
      assert html =~ "<em>italic</em>"
      assert html =~ "<ul>"
      assert html =~ "<li>Item one</li>"
      assert html =~ "href=\"https://example.com/menu\""
      refute html =~ "youtu.be"
      refute html =~ "youtube.com"
    end

    test "does not show hotels section in day-by-day plan" do
      trip = trip_fixture(%{dates_unknown: true, duration: 3})

      html = trip_html(trip)

      refute html =~ "Hotels we stay in"
    end

    test "renders transfer route with stations and omits transfer notes" do
      geonames_fixture()

      trip = trip_fixture(%{dates_unknown: true, duration: 3})
      berlin = Geo.find_city_by_geonames_id("2950159")
      hamburg = Geo.find_city_by_geonames_id("2911298")
      note_token = "TRANSFER_NOTE_TOKEN_926f2aeb"

      {:ok, _transfer} =
        Planning.create_transfer(trip, %{
          transport_mode: "flight",
          departure_city_id: berlin.id,
          arrival_city_id: hamburg.id,
          departure_time: "09:30",
          arrival_time: "11:30",
          vessel_number: "EHU32",
          carrier: "Ehuenno Air",
          departure_station: "POL",
          arrival_station: "JUE",
          day_index: 0,
          note: note_token
        })

      html = trip_html(trip)

      assert html =~ "(POL)"
      assert html =~ "(JUE)"
      refute html =~ note_token
    end

    test "renders all transport mode icons as inline svg" do
      geonames_fixture()

      trip = trip_fixture(%{dates_unknown: true, duration: 3})
      berlin = Geo.find_city_by_geonames_id("2950159")
      hamburg = Geo.find_city_by_geonames_id("2911298")

      modes = ["flight", "train", "bus", "car", "taxi", "boat"]

      Enum.each(modes, fn mode ->
        {:ok, _transfer} =
          Planning.create_transfer(trip, %{
            transport_mode: mode,
            departure_city_id: berlin.id,
            arrival_city_id: hamburg.id,
            departure_time: "09:00",
            arrival_time: "11:00",
            day_index: 0
          })
      end)

      html = trip_html(trip)

      Enum.each(modes, fn mode ->
        assert html =~ ~s(data-transport-icon="#{mode}")
      end)

      refute html =~ "🚆"
      refute html =~ "🚌"
      refute html =~ "🚗"
      refute html =~ "🚕"
      refute html =~ "⛴"
      refute html =~ "✈"
    end

    test "overview prints hotel description only for first appearance of each hotel" do
      trip = trip_fixture(%{dates_unknown: true, duration: 4})

      alpha_note_token = "HOTEL_ALPHA_NOTE_TOKEN_8b5b9a6a"
      bravo_note_token = "HOTEL_BRAVO_NOTE_TOKEN_31b4f6ce"

      {:ok, _alpha} =
        Planning.create_accommodation(trip, %{
          name: "Hotel Alpha",
          address: "Alpha street 1",
          note: "<p>#{alpha_note_token}</p>",
          start_day: 0,
          end_day: 2
        })

      {:ok, _bravo} =
        Planning.create_accommodation(trip, %{
          name: "Hotel Bravo",
          address: "Bravo street 2",
          note: "<p>#{bravo_note_token}</p>",
          start_day: 1,
          end_day: 3
        })

      html = trip_html(trip)

      assert count_occurrences(html, alpha_note_token) == 1
      assert count_occurrences(html, bravo_note_token) == 1
    end
  end

  describe "render/2" do
    test "delegates to configured renderer and includes page-number options" do
      trip = trip_fixture() |> Map.fetch!(:id) |> Planning.get_trip!()

      with_renderer(CaptureRenderer, fn ->
        assert {:ok, "<<pdf-binary>>"} = TripPdf.render(trip, "EUR")

        assert_received {:capture_renderer_called, html, opts}
        assert html =~ trip.name

        assert Keyword.keyword?(opts)
        print_opts = Keyword.fetch!(opts, :print_to_pdf)
        assert print_opts.displayHeaderFooter == true
        assert print_opts.headerTemplate == "<span></span>"
        assert print_opts.footerTemplate =~ "pageNumber"
        assert print_opts.footerTemplate =~ "totalPages"
      end)
    end

    test "returns renderer errors as-is" do
      trip = trip_fixture() |> Map.fetch!(:id) |> Planning.get_trip!()

      with_renderer(ErrorRenderer, fn ->
        assert {:error, :renderer_failed} = TripPdf.render(trip, "EUR")
      end)
    end
  end

  defp count_occurrences(text, needle) do
    text
    |> String.split(needle)
    |> length()
    |> Kernel.-(1)
  end

  defp with_renderer(renderer, fun) do
    original = Application.get_env(:hamster_travel, :trip_pdf_renderer)
    Application.put_env(:hamster_travel, :trip_pdf_renderer, renderer)

    try do
      fun.()
    after
      Application.put_env(:hamster_travel, :trip_pdf_renderer, original)
    end
  end

  defp trip_html(trip) do
    trip
    |> Map.fetch!(:id)
    |> Planning.get_trip!()
    |> TripPdf.to_html("EUR")
  end
end
