defmodule HamsterTravelWeb.TripPdfTest do
  use HamsterTravel.DataCase

  alias HamsterTravel.Geo
  alias HamsterTravel.Planning
  alias HamsterTravelWeb.Gettext, as: HTGettext
  alias HamsterTravelWeb.TripPdf

  import ExUnit.CaptureLog
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

  defmodule FallbackRenderer do
    @behaviour HamsterTravelWeb.TripPdf.Renderer

    @impl true
    def render(_html, opts) do
      send(self(), {:fallback_renderer_called, opts})
      {:ok, "<<fallback-pdf>>"}
    end
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

    test "renders budget categories in the expense summary" do
      trip = trip_fixture(%{dates_unknown: true, duration: 3})
      food_category = Planning.get_food_budget_category!(trip)

      assert {:ok, _food_category} =
               Planning.update_budget_category(food_category, %{
                 food_setting: %{
                   price_per_day: Money.new(:EUR, 10),
                   days_count: 3,
                   people_count: 2,
                   calculation_mode: "per_day"
                 }
               })

      assert {:ok, _category} =
               Planning.create_budget_category(trip, %{
                 name: "PDF Souvenirs",
                 estimated_expense: %{price: Money.new(:EUR, 75)}
               })

      html = trip_html(trip)

      assert html =~ "Food"
      assert html =~ "PDF Souvenirs"
      assert html =~ "per day"
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

    test "allows long note and activity cards to flow across PDF pages" do
      geonames_fixture()

      trip = trip_fixture(%{dates_unknown: true, duration: 3})
      berlin = Geo.find_city_by_geonames_id("2950159")
      hamburg = Geo.find_city_by_geonames_id("2911298")

      {:ok, _transfer} =
        Planning.create_transfer(trip, %{
          transport_mode: "train",
          departure_city_id: berlin.id,
          arrival_city_id: hamburg.id,
          departure_time: "09:00",
          arrival_time: "11:00",
          day_index: 0
        })

      long_note_token = "LONG_NOTE_TOKEN_704c2bb5"
      long_activity_token = "LONG_ACTIVITY_TOKEN_729f1cef"

      long_paragraph =
        String.duplicate("PDF page flow should keep filling the current page. ", 80)

      {:ok, _note} =
        Planning.create_note(trip, %{
          title: "Long note",
          text: "<p>#{long_note_token}</p><p>#{long_paragraph}</p>",
          day_index: 0
        })

      {:ok, _activity} =
        Planning.create_activity(trip, %{
          name: "Long activity",
          day_index: 0,
          priority: 2,
          description: "<p>#{long_activity_token}</p><p>#{long_paragraph}</p>"
        })

      html = trip_html(trip)

      assert html =~ ~s(class="card transfer-card")
      assert html =~ ~s(class="card note-card")
      assert html =~ ~s(class="card activity-card")
      assert html =~ long_note_token
      assert html =~ long_activity_token

      card_rule = css_rule(html, ".card")
      refute card_rule =~ "break-inside: avoid"
      refute card_rule =~ "page-break-inside: avoid"
      assert card_rule =~ "break-inside: auto"
      assert card_rule =~ "page-break-inside: auto"

      section_rule = css_rule(html, ".section")
      refute section_rule =~ "break-inside: avoid"
      assert section_rule =~ "break-inside: auto"

      transfer_rule = css_rule(html, ".transfer-card")
      assert transfer_rule =~ "break-inside: avoid-page"
      assert transfer_rule =~ "page-break-inside: avoid"

      flowable_rule = css_rule(html, ".activity-card,")
      assert flowable_rule =~ ".note-card"
      assert flowable_rule =~ ".rich-text p"
      assert flowable_rule =~ "break-inside: auto"
      assert flowable_rule =~ "page-break-inside: auto"
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

  describe "FlameChromicRenderer.render/2" do
    test "falls back locally when FLAME call raises and redacts token-bearing errors" do
      fly_token = "fm2_sensitive-token-that-must-not-appear"

      flame_call = fn _pool, _fun, opts ->
        send(self(), {:flame_call_opts, opts})
        raise "failed POST https://api.machines.dev with 403: Authorization Bearer #{fly_token}"
      end

      log =
        capture_log(fn ->
          with_flame_renderer_config([flame_call: flame_call, fallback: true], fn ->
            assert {:ok, "<<fallback-pdf>>"} =
                     TripPdf.FlameChromicRenderer.render("<html></html>", print_to_pdf: %{})
          end)
        end)

      assert_received {:flame_call_opts, opts}
      assert Keyword.fetch!(opts, :link) == false
      assert Keyword.fetch!(opts, :timeout) == 120_000
      assert_received {:fallback_renderer_called, [print_to_pdf: %{}]}
      assert log =~ "falling back to local ChromicPDF"
      assert log =~ "Bearer [REDACTED]"
      refute log =~ fly_token
    end

    test "returns FLAME error when local fallback is disabled" do
      flame_call = fn _pool, _fun, _opts -> exit(:fly_unauthorized) end

      with_flame_renderer_config([flame_call: flame_call, fallback: false], fn ->
        assert {:error, {:flame_exit, :fly_unauthorized}} =
                 TripPdf.FlameChromicRenderer.render("<html></html>", [])
      end)

      refute_received {:fallback_renderer_called, _opts}
    end
  end

  defp count_occurrences(text, needle) do
    text
    |> String.split(needle)
    |> length()
    |> Kernel.-(1)
  end

  defp css_rule(html, selector) do
    selector
    |> css_rule_regex()
    |> Regex.run(html)
    |> List.first()
  end

  defp css_rule_regex(selector) do
    selector
    |> Regex.escape()
    |> then(&~r/#{&1}[^{}]*\{([^}]*)\}/)
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

  defp with_flame_renderer_config(opts, fun) do
    original_flame_call = Application.get_env(:hamster_travel, :trip_pdf_flame_call)
    original_fallback = Application.get_env(:hamster_travel, :trip_pdf_flame_fallback)
    original_chromic_renderer = Application.get_env(:hamster_travel, :trip_pdf_chromic_renderer)

    Application.put_env(:hamster_travel, :trip_pdf_flame_call, Keyword.fetch!(opts, :flame_call))

    Application.put_env(
      :hamster_travel,
      :trip_pdf_flame_fallback,
      Keyword.fetch!(opts, :fallback)
    )

    Application.put_env(:hamster_travel, :trip_pdf_chromic_renderer, FallbackRenderer)

    try do
      fun.()
    after
      restore_env(:trip_pdf_flame_call, original_flame_call)
      restore_env(:trip_pdf_flame_fallback, original_fallback)
      restore_env(:trip_pdf_chromic_renderer, original_chromic_renderer)
    end
  end

  defp restore_env(key, nil), do: Application.delete_env(:hamster_travel, key)
  defp restore_env(key, value), do: Application.put_env(:hamster_travel, key, value)

  defp trip_html(trip) do
    trip
    |> Map.fetch!(:id)
    |> Planning.get_trip!()
    |> TripPdf.to_html("EUR")
  end
end
