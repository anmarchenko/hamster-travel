defmodule HamsterTravelWeb.TripPdf do
  @moduledoc false

  use Gettext, backend: HamsterTravelWeb.Gettext

  alias HamsterTravel.Geo
  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.Accommodation
  alias HamsterTravel.Planning.Trip
  alias HamsterTravel.Utilities.HtmlScrubber
  alias HamsterTravelWeb.Cldr
  alias Phoenix.HTML

  @renderer_env :trip_pdf_renderer

  defmodule Renderer do
    @moduledoc false

    @callback render(String.t(), keyword()) :: {:ok, binary()} | {:error, term()}
  end

  defmodule ChromicRenderer do
    @moduledoc false
    @behaviour HamsterTravelWeb.TripPdf.Renderer
    @trip_pdf_lock {:hamster_travel, :trip_pdf_chromic_lock}

    @impl true
    def render(html, opts \\ []) do
      :global.trans(@trip_pdf_lock, fn ->
        with {:ok, encoded_pdf} <- ChromicPDF.print_to_pdf({:html, html}, opts),
             {:ok, pdf_binary} <- Base.decode64(encoded_pdf) do
          {:ok, pdf_binary}
        else
          :error -> {:error, :invalid_pdf_data}
          {:error, reason} -> {:error, reason}
        end
      end)
    end
  end

  @spec render(Trip.t(), String.t()) :: {:ok, binary()} | {:error, term()}
  def render(%Trip{} = trip, display_currency) when is_binary(display_currency) do
    trip
    |> to_html(display_currency)
    |> renderer().render(pdf_options())
  end

  @spec to_html(Trip.t(), String.t()) :: String.t()
  def to_html(%Trip{} = trip, display_currency) do
    day_sections =
      trip
      |> day_indices()
      |> Enum.map(&day_section_data(trip, &1))

    day_sections_html =
      case day_sections do
        [] ->
          ""

        _ ->
          day_sections
          |> Enum.map_join("\n", &day_section_html(&1, display_currency))
      end

    {overview_rows, _shown_hotel_keys} =
      day_sections
      |> Enum.map_reduce(MapSet.new(), fn day_data, shown_hotel_keys ->
        overview_row_html(day_data, display_currency, shown_hotel_keys)
      end)

    overview_rows_html = Enum.join(overview_rows, "\n")

    whole_trip_notes_html = trip_notes_html(trip)

    food_notes_section_html =
      if blank?(whole_trip_notes_html) do
        ""
      else
        """
        <section class="section">
          <h2>#{escape_html(gettext("Whole-trip notes"))}</h2>
          #{whole_trip_notes_html}
        </section>
        """
      end

    language = escape_html(Gettext.get_locale(HamsterTravelWeb.Gettext))

    """
    <!doctype html>
    <html lang="#{language}">
      <head>
        <meta charset="utf-8" />
        <title>#{escape_html(trip.name)} - #{escape_html(gettext("Trip plan"))}</title>
        <style>
          @page {
            size: A4 portrait;
            margin: 6mm;
          }

          @page overview {
            size: A4 landscape;
            margin: 6mm;
          }

          body {
            font-family: Arial, Helvetica, sans-serif;
            color: #111827;
            font-size: 11px;
            line-height: 1.3;
            margin: 0;
          }

          h1 {
            font-size: 23px;
            margin: 0 0 5px;
          }

          h2 {
            font-size: 17px;
            margin: 0 0 6px;
            break-after: avoid-page;
            page-break-after: avoid;
          }

          h3 {
            font-size: 14px;
            margin: 7px 0 3px;
          }

          h4 {
            font-size: 12px;
            margin: 8px 0 4px;
          }

          p {
            margin: 0 0 4px;
          }

          .muted {
            color: #4b5563;
          }

          .empty {
            color: #6b7280;
            font-style: italic;
          }

          .page-title {
            margin-bottom: 8px;
            border-bottom: 1px solid #d1d5db;
            padding-bottom: 5px;
          }

          .section {
            padding: 0;
            margin-bottom: 10px;
            break-inside: avoid;
          }

          .day-section {
            padding: 0;
            margin-bottom: 10px;
            break-inside: auto;
            page-break-inside: auto;
          }

          .overview-page {
            page: overview;
            break-before: page;
          }

          .day-by-day {
            break-inside: auto;
            page-break-inside: auto;
          }

          .day-cities {
            display: flex;
            flex-wrap: wrap;
            gap: 5px;
            margin: 4px 0 6px;
          }

          .city-chip {
            display: inline-flex;
            align-items: center;
            border: 1px solid #cbd5e1;
            border-radius: 999px;
            padding: 1px 7px;
            font-size: 0.76em;
            font-weight: 600;
          }

          .day-block {
            margin-bottom: 6px;
          }

          .stack {
            display: flex;
            flex-direction: column;
            gap: 5px;
          }

          .transfer-stack {
            gap: 2px;
          }

          .card {
            border: none;
            border-radius: 8px;
            background: transparent;
            padding: 6px 8px;
            break-inside: avoid;
            break-inside: avoid-page;
            page-break-inside: avoid;
            -webkit-column-break-inside: avoid;
          }

          .card-header {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 6px;
            margin-bottom: 2px;
          }

          .card-title {
            font-weight: 800;
            line-height: 1.2;
          }

          .card-price {
            font-weight: 800;
            white-space: nowrap;
          }

          .card-meta {
            color: #1f2937;
          }

          .card-note {
            color: #475569;
          }

          .rich-text p {
            margin: 0 0 4px;
          }

          .rich-text ul,
          .rich-text ol {
            margin: 4px 0 6px 16px;
            padding: 0;
          }

          .rich-text li {
            margin: 0 0 2px;
          }

          .rich-text ul[data-task-list] {
            list-style: none;
            margin-left: 0;
          }

          .rich-text ul[data-task-list] li,
          .rich-text li[data-type="taskItem"] {
            list-style: none;
            position: relative;
            padding-left: 15px;
          }

          .rich-text ul[data-task-list] li::before,
          .rich-text li[data-type="taskItem"]::before {
            content: "◻";
            position: absolute;
            left: 0;
            top: 0;
            font-weight: 700;
          }

          .rich-text ul[data-task-list] li[data-checked="true"]::before,
          .rich-text li[data-type="taskItem"][data-checked="true"]::before {
            content: "✓";
          }

          .rich-text ul[data-task-list] input[type="checkbox"],
          .rich-text li[data-type="taskItem"] input[type="checkbox"] {
            display: none;
          }

          .rich-text strong,
          .rich-text b {
            font-weight: 800;
          }

          .rich-text em,
          .rich-text i {
            font-style: italic;
          }

          .transfer-route {
            font-weight: 800;
            margin-bottom: 1px;
            display: flex;
            align-items: center;
            gap: 4px;
          }

          .transfer-icon {
            display: inline-flex;
            width: 14px;
            height: 14px;
            flex-shrink: 0;
          }

          .transfer-icon-svg {
            display: block;
            width: 100%;
            height: 100%;
          }

          .expense-total {
            font-size: 1.05em;
            font-weight: 900;
            margin-bottom: 5px;
          }

          .expense-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 4px;
            margin-bottom: 5px;
          }

          .expense-cell {
            border: 1px solid #d5dee9;
            border-radius: 6px;
            background: transparent;
            padding: 4px 6px;
            display: flex;
            align-items: baseline;
            justify-content: space-between;
            gap: 5px;
            font-size: 0.82em;
          }

          .expense-label {
            color: #475569;
            font-weight: 600;
          }

          .expense-value {
            font-weight: 800;
            white-space: nowrap;
          }

          .expense-item-row {
            display: flex;
            align-items: baseline;
            justify-content: space-between;
            gap: 7px;
            padding: 2px 0;
            border-bottom: none;
          }

          .expense-item-row:last-child {
            border-bottom: none;
          }

          .note-block {
            white-space: pre-wrap;
          }

          table {
            width: 100%;
            border-collapse: collapse;
            table-layout: fixed;
            font-size: 11px;
          }

          th,
          td {
            border: 1px solid #9ca3af;
            vertical-align: top;
            padding: 5px;
            overflow-wrap: anywhere;
            word-break: break-word;
          }

          th {
            background: transparent;
            text-align: left;
          }

          .table-sub {
            display: block;
            margin-top: 1px;
            color: #475569;
            font-size: 0.82em;
            font-weight: 500;
          }

          .overview-table col.overview-col-day {
            width: 16%;
          }

          .overview-day-column {
            white-space: normal;
            font-weight: 700;
          }

        </style>
      </head>
      <body>
        <section class="page-title">
          <h1>#{escape_html(trip.name)}</h1>
          <p>#{escape_html(trip_dates(trip))}</p>
        </section>

        <section class="section">
          <h2>#{escape_html(gettext("Expenses"))}</h2>
          #{expense_summary_html(trip, display_currency)}
        </section>

        <section class="day-by-day">
          <h2>#{escape_html(gettext("Day-by-day plan"))}</h2>
          #{day_sections_html}
        </section>

        <section class="overview-page">
          <h2>#{escape_html(gettext("Transfers and hotels overview"))}</h2>
          <table class="overview-table">
            <colgroup>
              <col class="overview-col-day" />
              <col />
              <col />
              <col />
            </colgroup>
            <thead>
              <tr>
                <th class="overview-day-column">#{escape_html(gettext("Day"))}</th>
                <th>#{escape_html(gettext("Cities"))}</th>
                <th>#{escape_html(gettext("Transfers"))}</th>
                <th>#{escape_html(gettext("Hotels"))}</th>
              </tr>
            </thead>
            <tbody>
              #{overview_rows_html}
            </tbody>
          </table>
        </section>

        #{food_notes_section_html}
      </body>
    </html>
    """
  end

  defp renderer do
    Application.get_env(:hamster_travel, @renderer_env, HamsterTravelWeb.TripPdf.ChromicRenderer)
  end

  defp pdf_options do
    [
      print_to_pdf: %{
        printBackground: true,
        preferCSSPageSize: true,
        scale: 1.2,
        displayHeaderFooter: true,
        headerTemplate: "<span></span>",
        footerTemplate: pdf_footer_template(),
        marginTop: 0.24,
        marginBottom: 0.5
      }
    ]
  end

  defp pdf_footer_template do
    """
    <style>
      .pdf-footer {
        width: 100%;
        padding: 0 8mm;
        box-sizing: border-box;
        text-align: right;
        font-size: 8px;
        color: #6b7280;
        font-family: Arial, Helvetica, sans-serif;
      }
    </style>
    <div class="pdf-footer">
      <span class="pageNumber"></span>/<span class="totalPages"></span>
    </div>
    """
    |> String.trim()
  end

  defp day_indices(%Trip{duration: duration}) when is_integer(duration) and duration > 0 do
    0..(duration - 1)
    |> Enum.to_list()
  end

  defp day_indices(_trip), do: []

  defp day_section_data(trip, day_index) do
    cities =
      Planning.items_for_day(day_index, trip.destinations)
      |> Enum.map(&safe_city_name(&1.city))
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    accommodations = Planning.items_for_day(day_index, trip.accommodations)
    transfers = Planning.transfers_for_day(day_index, trip.transfers)
    day_expenses = Planning.day_expenses_for_day(day_index, trip.day_expenses)
    notes = Planning.notes_for_day(day_index, trip.notes)
    activities = Planning.activities_for_day(day_index, trip.activities)

    accommodation_costs =
      accommodations
      |> Enum.map(fn accommodation ->
        Accommodation.price_per_night(accommodation) || expense_price(accommodation)
      end)
      |> Enum.reject(&is_nil/1)

    transfer_total = sum_expense_entities(transfers, trip.currency)
    day_expense_total = sum_expense_entities(day_expenses, trip.currency)
    activity_total = sum_expense_entities(activities, trip.currency)
    accommodation_total = sum_money(accommodation_costs, trip.currency)

    %{
      day_index: day_index,
      day_label: day_label(trip, day_index),
      cities: cities,
      accommodations: accommodations,
      transfers: transfers,
      day_expenses: day_expenses,
      notes: notes,
      activities: activities,
      transfer_total: transfer_total,
      day_expense_total: day_expense_total,
      activity_total: activity_total,
      accommodation_total: accommodation_total,
      daily_total:
        sum_money(
          [transfer_total, day_expense_total, activity_total, accommodation_total],
          trip.currency
        )
    }
  end

  defp day_section_html(day_data, display_currency) do
    """
    <article class="day-section">
      <h3>#{escape_html(day_data.day_label)}</h3>
      #{cities_html(day_data.cities)}
      #{section_block_html(gettext("Transfers planned today"), transfers_html(day_data.transfers, display_currency))}
      #{section_block_html(gettext("All expenses planned for today"), daily_expenses_summary_html(day_data, display_currency))}
      #{section_block_html(gettext("Notes for today"), notes_html(day_data.notes))}
      #{section_block_html(gettext("All activities"), activities_html(day_data.activities, display_currency))}
    </article>
    """
  end

  defp section_block_html(_title, ""), do: ""

  defp section_block_html(title, body_html) do
    """
    <section class="day-block">
      <h4>#{escape_html(title)}</h4>
      #{body_html}
    </section>
    """
  end

  defp cities_html([]), do: ""

  defp cities_html(cities) do
    items_html =
      Enum.map_join(cities, "", fn city ->
        "<span class=\"city-chip\">#{escape_html(city)}</span>"
      end)

    "<div class=\"day-cities\">#{items_html}</div>"
  end

  defp transfers_html([], _display_currency), do: ""

  defp transfers_html(transfers, display_currency) do
    items_html =
      Enum.map_join(transfers, "", fn transfer ->
        departure_city = safe_city_name(transfer.departure_city) || gettext("Unknown city")
        arrival_city = safe_city_name(transfer.arrival_city) || gettext("Unknown city")

        departure_route_point =
          city_with_optional_station(departure_city, transfer.departure_station)

        arrival_route_point = city_with_optional_station(arrival_city, transfer.arrival_station)
        route = "#{departure_route_point} -> #{arrival_route_point}"
        transport_mode = transport_mode_label(transfer.transport_mode)
        transport_icon = transport_mode_icon_html(transfer.transport_mode)

        time_text =
          join_with_arrow([
            format_time(transfer.departure_time),
            format_time(transfer.arrival_time)
          ])

        vessel_info =
          [transfer.vessel_number, transfer.carrier]
          |> Enum.reject(&blank?/1)
          |> Enum.join(" · ")

        meta_html =
          [time_text, vessel_info]
          |> Enum.reject(&blank?/1)
          |> Enum.map_join("", fn line ->
            "<div class=\"card-meta\">#{escape_with_breaks(line)}</div>"
          end)

        """
        <article class="card transfer-card">
          <div class="card-header">
            <div>
              <div class="transfer-route" title="#{escape_html(transport_mode)}">
                <span class="transfer-icon">#{transport_icon}</span>
                <span>#{escape_html(route)}</span>
              </div>
            </div>
            #{card_price_html(money_text(expense_price(transfer), display_currency))}
          </div>
          #{meta_html}
        </article>
        """
      end)

    "<div class=\"stack transfer-stack\">#{items_html}</div>"
  end

  defp daily_expenses_summary_html(day_data, display_currency) do
    item_details =
      Enum.map_join(day_data.day_expenses, "", fn day_expense ->
        """
        <div class="expense-item-row">
          <span>#{escape_html(day_expense.name)}</span>
          <span class="card-price">#{escape_html(money_text(expense_price(day_expense), display_currency))}</span>
        </div>
        """
      end)

    if item_details == "" do
      ""
    else
      """
      <div class="expense-total">#{escape_html(money_text(day_data.day_expense_total, display_currency))}</div>
      <div class="stack">#{item_details}</div>
      """
    end
  end

  defp notes_html([]), do: ""

  defp notes_html(notes) do
    items_html =
      Enum.map_join(notes, "", fn note ->
        text_html =
          rich_text_block_html(note.text, "card-meta")

        """
        <article class="card note-card">
          <div class="card-title">#{escape_html(note.title)}</div>
          #{text_html}
        </article>
        """
      end)

    "<div class=\"stack\">#{items_html}</div>"
  end

  defp activities_html([], _display_currency), do: ""

  defp activities_html(activities, display_currency) do
    items_html =
      activities
      |> Enum.with_index(1)
      |> Enum.map_join("", fn {activity, index} ->
        address_html =
          case activity.address do
            nil -> ""
            "" -> ""
            address -> "<div class=\"card-meta\">#{escape_with_breaks(address)}</div>"
          end

        description_html =
          rich_text_block_html(activity.description, "card-note")

        """
        <article class="card activity-card">
          <div class="card-header">
            <div class="card-title">#{escape_html("#{index}. #{activity.name}")}</div>
            #{card_price_html(money_text(expense_price(activity), display_currency))}
          </div>
          #{address_html}
          #{description_html}
        </article>
        """
      end)

    "<div class=\"stack\">#{items_html}</div>"
  end

  defp overview_row_html(day_data, display_currency, shown_hotel_keys) do
    cities_html =
      case day_data.cities do
        [] -> "<span class=\"muted\">-</span>"
        cities -> escape_html(Enum.join(cities, " · "))
      end

    transfers_cards_html =
      case transfers_html(day_data.transfers, display_currency) do
        "" -> "<span class=\"muted\">-</span>"
        html -> html
      end

    {hotels_cards_html, updated_hotel_keys} =
      overview_hotels_html(day_data.accommodations, display_currency, shown_hotel_keys)

    row_html = """
    <tr>
      <td class="overview-day-column">#{escape_html(day_data.day_label)}</td>
      <td>#{cities_html}</td>
      <td>#{transfers_cards_html}</td>
      <td>#{hotels_cards_html}</td>
    </tr>
    """

    {row_html, updated_hotel_keys}
  end

  defp overview_hotels_html([], _display_currency, shown_hotel_keys),
    do: {"<span class=\"muted\">-</span>", shown_hotel_keys}

  defp overview_hotels_html(accommodations, display_currency, shown_hotel_keys) do
    {cards, updated_hotel_keys} =
      Enum.map_reduce(accommodations, shown_hotel_keys, fn accommodation, acc ->
        hotel_key = accommodation_identity(accommodation)
        show_note? = not MapSet.member?(acc, hotel_key)
        new_acc = MapSet.put(acc, hotel_key)
        {accommodation_card_html(accommodation, display_currency, show_note?), new_acc}
      end)

    {~s(<div class="stack">#{Enum.join(cards, "")}</div>), updated_hotel_keys}
  end

  defp expense_summary_html(trip, display_currency) do
    category_rows =
      [
        %{
          label: gettext("Transfers"),
          amount: sum_expense_entities(trip.transfers, trip.currency),
          detail: nil
        },
        %{
          label: gettext("Hotels"),
          amount: sum_expense_entities(trip.accommodations, trip.currency),
          detail: nil
        },
        %{
          label: gettext("Activities"),
          amount: sum_expense_entities(trip.activities, trip.currency),
          detail: nil
        },
        %{
          label: gettext("Day expenses"),
          amount: sum_expense_entities(trip.day_expenses, trip.currency),
          detail: nil
        },
        %{
          label: gettext("Food"),
          amount: food_total(trip),
          detail: food_formula_text(trip, display_currency)
        }
      ]
      |> Enum.map_join("\n", fn %{label: label, amount: amount, detail: detail} ->
        """
        <tr>
          <td>#{escape_html(label)}</td>
          <td>
            #{escape_html(money_text(amount, display_currency))}
            #{if blank?(detail), do: "", else: "<span class=\"table-sub\">#{escape_html(detail)}</span>"}
          </td>
        </tr>
        """
      end)

    overall_total =
      trip
      |> Map.put(:expenses, Planning.list_expenses(trip))
      |> Planning.calculate_budget()
      |> money_text(display_currency)

    """
    <table>
      <thead>
        <tr>
          <th>#{escape_html(gettext("Category"))}</th>
          <th>#{escape_html(gettext("Amount"))}</th>
        </tr>
      </thead>
      <tbody>
        #{category_rows}
        <tr>
          <td><strong>#{escape_html(gettext("Total"))}</strong></td>
          <td><strong>#{escape_html(overall_total)}</strong></td>
        </tr>
      </tbody>
    </table>
    """
  end

  defp trip_notes_html(trip) do
    notes = Planning.notes_unassigned(trip.notes)

    if notes == [] do
      ""
    else
      notes_html(notes)
    end
  end

  defp day_label(%Trip{start_date: %Date{} = start_date}, day_index) do
    start_date
    |> Date.add(day_index)
    |> Cldr.date_with_weekday()
  end

  defp day_label(_trip, day_index) do
    gettext("Day %{number}", number: day_index + 1)
  end

  defp trip_dates(%Trip{start_date: %Date{} = start_date, end_date: %Date{} = end_date}) do
    "#{short_date(start_date)} - #{short_date(end_date)}"
  end

  defp trip_dates(%Trip{duration: duration}) when is_integer(duration) and duration > 0 do
    "#{duration} #{ngettext("day", "days", duration)}"
  end

  defp trip_dates(_trip), do: ""

  defp short_date(date) do
    Cldr.Date.to_string!(date, format: "dd.MM.yyyy")
  end

  defp format_time(nil), do: nil

  defp format_time(datetime) do
    Cldr.format_time(datetime)
  end

  defp safe_city_name(nil), do: nil
  defp safe_city_name(city), do: Geo.city_name(city)

  defp expense_price(%{expense: %{price: %Money{} = price}}), do: price
  defp expense_price(_), do: nil

  defp sum_expense_entities(entities, currency) do
    entities
    |> Enum.map(&expense_price/1)
    |> Enum.reject(&is_nil/1)
    |> sum_money(currency)
  end

  defp sum_money(moneys, currency) do
    Enum.reduce(moneys, Money.new(currency, 0), fn money, acc ->
      case Money.to_currency(money, currency) do
        {:ok, converted} ->
          Money.add!(acc, converted)

        {:error, _} ->
          acc
      end
    end)
  end

  defp food_total(%Trip{food_expense: nil, currency: currency}), do: Money.new(currency, 0)

  defp food_total(%Trip{food_expense: food_expense, currency: currency}) do
    expense_price(food_expense) || Money.new(currency, 0)
  end

  defp food_formula_text(%Trip{food_expense: nil}, _display_currency), do: nil

  defp food_formula_text(%Trip{food_expense: food_expense}, display_currency) do
    per_day = money_text(food_expense.price_per_day, display_currency)
    total = money_text(expense_price(food_expense), display_currency)
    days_label = ngettext("day", "days", food_expense.days_count)
    people_label = ngettext("person", "people", food_expense.people_count)

    "#{per_day} #{gettext("per day")} x #{food_expense.days_count} #{days_label} x #{food_expense.people_count} #{people_label} = #{total}"
  end

  defp money_text(nil, _display_currency), do: "-"

  defp money_text(%Money{} = money, display_currency) do
    {display_money, _original, _converted?} =
      Cldr.convert_money_for_display(money, display_currency)

    Cldr.format_money(display_money.amount, display_money.currency)
  end

  defp rich_text_block_html(text, base_class) do
    case rich_text_html(text) do
      nil -> ""
      "" -> ""
      html -> "<div class=\"#{base_class} rich-text\">#{html}</div>"
    end
  end

  defp rich_text_html(nil), do: nil

  defp rich_text_html(text) when is_binary(text) do
    sanitized_text =
      text
      |> HtmlSanitizeEx.Scrubber.scrub(HtmlScrubber)
      |> strip_youtube_content()

    if rich_text_present?(sanitized_text) do
      sanitized_text
    else
      ""
    end
  end

  defp rich_text_html(_), do: ""

  defp strip_youtube_content(text) do
    text
    |> String.replace(
      ~r/<iframe\b[^>]*src\s*=\s*["'][^"']*(?:youtube(?:-nocookie)?\.com|youtu\.be)[^"']*["'][^>]*>.*?<\/iframe>/isu,
      ""
    )
    |> String.replace(
      ~r/<a\b[^>]*href\s*=\s*["'][^"']*(?:youtube(?:-nocookie)?\.com|youtu\.be)[^"']*["'][^>]*>.*?<\/a>/isu,
      ""
    )
    |> String.replace(~r/https?:\/\/(?:www\.)?(?:youtube(?:-nocookie)?\.com|youtu\.be)\S*/iu, "")
  end

  defp rich_text_present?(text) when is_binary(text) do
    text
    |> String.replace(~r/<[^>]*>/, "")
    |> String.replace("&nbsp;", " ")
    |> String.trim()
    |> Kernel.!=("")
  end

  defp rich_text_present?(_), do: false

  defp accommodation_card_html(accommodation, display_currency, show_note?) do
    nightly_cost =
      Accommodation.price_per_night(accommodation) || expense_price(accommodation)

    total_cost = expense_price(accommodation)
    price_text = accommodation_price_line(nightly_cost, total_cost, display_currency)

    meta_html =
      [accommodation.address]
      |> Enum.reject(&blank?/1)
      |> Enum.map_join("", fn line ->
        "<div class=\"card-meta\">#{escape_with_breaks(line)}</div>"
      end)

    note_html =
      if show_note? do
        rich_text_block_html(accommodation.note, "card-note")
      else
        ""
      end

    """
    <article class="card stay-card">
      <div class="card-header">
        <div class="card-title">#{escape_html(accommodation.name)}</div>
        #{card_price_html(price_text)}
      </div>
      #{meta_html}
      #{note_html}
    </article>
    """
  end

  defp accommodation_identity(%{id: id}) when not is_nil(id), do: {:id, id}

  defp accommodation_identity(accommodation) do
    {
      :attrs,
      normalized_string(accommodation.name),
      normalized_string(accommodation.address)
    }
  end

  defp normalized_string(nil), do: ""

  defp normalized_string(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
  end

  defp normalized_string(value), do: to_string(value)

  defp transport_mode_label("flight"), do: gettext("Flight")
  defp transport_mode_label("train"), do: gettext("Train")
  defp transport_mode_label("bus"), do: gettext("Bus")
  defp transport_mode_label("car"), do: gettext("Car")
  defp transport_mode_label("taxi"), do: gettext("Taxi")
  defp transport_mode_label("boat"), do: gettext("Boat")

  defp transport_mode_label(mode) when is_binary(mode) do
    mode
    |> String.trim()
    |> String.capitalize()
  end

  defp transport_mode_label(_), do: gettext("Transfer")

  defp transport_mode_icon_html("flight") do
    transport_icon_svg("flight", gettext("Flight"), """
    <path d="M10.5 4.5V9.16745C10.5 9.37433 10.3934 9.56661 10.218 9.67625L2.782 14.3237C2.60657 14.4334 2.5 14.6257 2.5 14.8325V15.7315C2.5 16.1219 2.86683 16.4083 3.24552 16.3136L9.75448 14.6864C10.1332 14.5917 10.5 14.8781 10.5 15.2685V18.2277C10.5 18.4008 10.4253 18.5654 10.2951 18.6793L8.13481 20.5695C7.6765 20.9706 8.03808 21.7204 8.63724 21.6114L11.8927 21.0195C11.9636 21.0066 12.0364 21.0066 12.1073 21.0195L15.3628 21.6114C15.9619 21.7204 16.3235 20.9706 15.8652 20.5695L13.7049 18.6793C13.5747 18.5654 13.5 18.4008 13.5 18.2277V15.2685C13.5 14.8781 13.8668 14.5917 14.2455 14.6864L20.7545 16.3136C21.1332 16.4083 21.5 16.1219 21.5 15.7315V14.8325C21.5 14.6257 21.3934 14.4334 21.218 14.3237L13.782 9.67625C13.6066 9.56661 13.5 9.37433 13.5 9.16745V4.5C13.5 3.67157 12.8284 3 12 3C11.1716 3 10.5 3.67157 10.5 4.5Z" />
    """)
  end

  defp transport_mode_icon_html("train") do
    transport_icon_svg("train", gettext("Train"), """
    <rect x="5" y="3.5" width="14" height="14" rx="3" />
    <path d="M8 8H16" />
    <circle cx="9" cy="13.5" r="1.2" fill="currentColor" stroke="none" />
    <circle cx="15" cy="13.5" r="1.2" fill="currentColor" stroke="none" />
    <path d="M9 17.5L7.5 20.5" />
    <path d="M15 17.5L16.5 20.5" />
    """)
  end

  defp transport_mode_icon_html("bus") do
    transport_icon_svg("bus", gettext("Bus"), """
    <rect x="5" y="3.5" width="14" height="15" rx="2" />
    <path d="M5 8.5H19" />
    <path d="M8 12H11" />
    <path d="M13 12H16" />
    <circle cx="8" cy="17.5" r="1.3" fill="currentColor" stroke="none" />
    <circle cx="16" cy="17.5" r="1.3" fill="currentColor" stroke="none" />
    """)
  end

  defp transport_mode_icon_html("car") do
    transport_icon_svg("car", gettext("Car"), """
    <path d="M6 13.5L7.5 9.5H16.5L18 13.5H6Z" />
    <rect x="4" y="13.5" width="16" height="4" rx="1" />
    <circle cx="7.5" cy="18.5" r="1.5" fill="currentColor" stroke="none" />
    <circle cx="16.5" cy="18.5" r="1.5" fill="currentColor" stroke="none" />
    <path d="M8 11H10.5" />
    <path d="M13.5 11H16" />
    """)
  end

  defp transport_mode_icon_html("taxi") do
    transport_icon_svg("taxi", gettext("Taxi"), """
    <rect x="9" y="7.5" width="6" height="1.8" rx="0.6" />
    <path d="M6 13.5L7.5 9.5H16.5L18 13.5H6Z" />
    <rect x="4" y="13.5" width="16" height="4" rx="1" />
    <path d="M10 7.5V6.3H14V7.5" />
    <circle cx="7.5" cy="18.5" r="1.5" fill="currentColor" stroke="none" />
    <circle cx="16.5" cy="18.5" r="1.5" fill="currentColor" stroke="none" />
    """)
  end

  defp transport_mode_icon_html("boat") do
    transport_icon_svg("boat", gettext("Boat"), """
    <path d="M4 14.5L12 16.5L20 14.5L18.5 18.5H5.5L4 14.5Z" />
    <path d="M12 4.5V13.5" />
    <path d="M12 5.5L16 8.5H12V5.5Z" fill="currentColor" stroke="none" />
    <path d="M3 20C4.2 18.8 5.8 18.8 7 20C8.2 21.2 9.8 21.2 11 20C12.2 18.8 13.8 18.8 15 20C16.2 21.2 17.8 21.2 19 20" />
    """)
  end

  defp transport_mode_icon_html(mode) do
    transport_icon_svg(transport_mode_data_key(mode), transport_mode_label(mode), """
    <path d="M4 12H20" />
    <path d="M14 6L20 12L14 18" />
    """)
  end

  defp transport_icon_svg(mode, title, body_html) do
    """
    <svg
      class="transfer-icon-svg"
      data-transport-icon="#{escape_html(mode)}"
      viewBox="0 0 24 24"
      role="img"
      aria-label="#{escape_html(title)}"
      fill="none"
      stroke="currentColor"
      stroke-width="1.8"
      stroke-linecap="round"
      stroke-linejoin="round"
      xmlns="http://www.w3.org/2000/svg"
    >
      #{body_html}
    </svg>
    """
  end

  defp transport_mode_data_key(mode) when is_binary(mode) do
    mode
    |> String.trim()
    |> String.downcase()
    |> case do
      "" -> "transfer"
      value -> value
    end
  end

  defp transport_mode_data_key(_), do: "transfer"

  defp blank?(nil), do: true
  defp blank?(value) when is_binary(value), do: String.trim(value) == ""
  defp blank?(_), do: false

  defp card_price_html(nil), do: ""
  defp card_price_html("-"), do: ""

  defp card_price_html(value) do
    "<div class=\"card-price\">#{escape_html(value)}</div>"
  end

  defp join_with_arrow(parts) do
    parts
    |> Enum.reject(&blank?/1)
    |> case do
      [] -> nil
      [single] -> single
      values -> Enum.join(values, " -> ")
    end
  end

  defp city_with_optional_station(city, station) do
    if blank?(station) do
      city
    else
      "#{city} (#{station})"
    end
  end

  defp accommodation_price_line(nightly_cost, total_cost, display_currency) do
    nightly = money_text(nightly_cost, display_currency)
    total = money_text(total_cost, display_currency)

    cond do
      nightly == "-" and total == "-" ->
        nil

      nightly == "-" ->
        total

      total == "-" ->
        "#{nightly} / #{gettext("night")}"

      true ->
        "#{nightly} / #{gettext("night")} · #{total}"
    end
  end

  defp escape_with_breaks(value) do
    value
    |> to_string()
    |> escape_html()
    |> String.replace("\n", "<br>")
  end

  defp escape_html(value) do
    value
    |> to_string()
    |> HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end
end
