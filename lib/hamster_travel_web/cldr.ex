defmodule HamsterTravelWeb.Cldr do
  @moduledoc """
  Locale data
  """

  @money_input_format "0.##################"

  use Cldr,
    default_locale: "en",
    locales: ["en", "ru"],
    precompile_number_formats: [@money_input_format],
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime]

  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.Trip
  alias HamsterTravelWeb.Cldr.Currency

  def format_money(val, currency) do
    HamsterTravelWeb.Cldr.Number.to_string!(val,
      format: :currency,
      currency: currency
    )
  end

  @spec format_money_input(Decimal.t(), String.t()) :: String.t()
  def format_money_input(%Decimal{} = amount, locale) do
    HamsterTravelWeb.Cldr.Number.to_string!(amount,
      locale: locale,
      format: @money_input_format,
      fractional_digits: Decimal.scale(amount)
    )
  end

  def date_with_weekday(date) do
    HamsterTravelWeb.Cldr.Date.to_string!(date, format: "dd.MM.yyyy EEEE")
  end

  def date_without_year(date) do
    HamsterTravelWeb.Cldr.Date.to_string!(date, format: "dd.MM")
  end

  def date_range(nil, _end_date), do: ""
  def date_range(_start_date, nil), do: ""

  def date_range(%Date{} = date, %Date{} = date) do
    date_with_year(date)
  end

  def date_range(%Date{year: year} = start_date, %Date{year: year} = end_date) do
    "#{date_without_year(start_date)} - #{date_with_year(end_date)}"
  end

  def date_range(%Date{} = start_date, %Date{} = end_date) do
    "#{date_with_year(start_date)} - #{date_with_year(end_date)}"
  end

  def year_with_month(nil), do: ""

  def year_with_month(date) do
    HamsterTravelWeb.Cldr.Date.to_string!(date, format: "LLLL yyyy")
  end

  def format_time(nil), do: nil

  def format_time(naive_datetime) do
    HamsterTravelWeb.Cldr.Time.to_string!(naive_datetime, format: "HH:mm")
  end

  def localize_currency(currency_code) do
    currency_name =
      currency_code
      |> Currency.currency_for_code!()
      |> Map.get(:name, "UNKNOWN")

    "#{currency_name} - #{currency_code}"
  end

  @spec trip_currencies(Trip.t(), String.t() | nil) :: [{atom(), atom()}]
  def trip_currencies(%Trip{} = trip, home_currency) do
    country_currencies =
      trip
      |> Planning.countries_by_trip_days()
      |> Enum.map(& &1.currency_code)

    all_currencies([home_currency || "EUR" | country_currencies])
  end

  @spec all_currencies([atom() | String.t() | nil]) :: [{atom(), atom()}]
  def all_currencies(preferred_currencies \\ []) do
    not_real_currencies = [
      :XAG,
      :XAU,
      :XXX,
      :CHE,
      :CHW,
      :CLF,
      :COU,
      :CUC,
      :XBA,
      :XBB,
      :XBC,
      :XBD,
      :XTS,
      :XCD,
      :SDR,
      :XOF,
      :XPD,
      :XPT,
      :XDR,
      :XPF,
      :XUA,
      :UYI,
      :UYW
    ]

    important_currencies = [
      :EUR,
      :USD,
      :GBP,
      :CHF,
      :CZK,
      :DKK,
      :HUF,
      :ISK,
      :NOK,
      :PLN,
      :SEK,
      :AUD,
      :CAD,
      :JPY
    ]

    known_currencies = Money.known_current_currencies()
    currencies_by_code = Map.new(known_currencies, &{to_string(&1), &1})

    preferred_currencies =
      preferred_currencies
      |> Enum.map(&Map.get(currencies_by_code, to_string(&1)))
      |> Enum.reject(&is_nil/1)

    other_currencies = Enum.reject(known_currencies, &(&1 in not_real_currencies))

    for currency <- Enum.uniq(preferred_currencies ++ important_currencies ++ other_currencies),
        do: {currency, currency}
  end

  def convert_money_for_display(money, display_currency) do
    original_money = money
    is_converted = to_string(original_money.currency) != display_currency

    {display_money, conversion_error} =
      if is_converted do
        case Money.to_currency(original_money, display_currency) do
          {:ok, converted_money} -> {converted_money, false}
          {:error, _} -> {original_money, true}
        end
      else
        {original_money, false}
      end

    {display_money, original_money, is_converted && !conversion_error}
  end

  defp date_with_year(date) do
    HamsterTravelWeb.Cldr.Date.to_string!(date, format: "dd.MM.yyyy")
  end
end
