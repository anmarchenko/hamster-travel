defmodule HamsterTravelWeb.Cldr do
  @moduledoc """
  Locale data
  """
  use Cldr,
    default_locale: "en",
    locales: ["en", "ru"],
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime, Money]

  alias HamsterTravelWeb.Cldr.Currency

  def format_money(val, currency) do
    HamsterTravelWeb.Cldr.Number.to_string!(val,
      format: :currency,
      currency: currency
    )
  end

  def date_with_weekday(date) do
    HamsterTravelWeb.Cldr.Date.to_string!(date, format: "dd.MM.yyyy EEEE")
  end

  def date_without_year(date) do
    HamsterTravelWeb.Cldr.Date.to_string!(date, format: "dd.MM")
  end

  def year_with_month(nil), do: ""

  def year_with_month(date) do
    HamsterTravelWeb.Cldr.Date.to_string!(date, format: "LLLL yyyy")
  end

  def localize_currency(currency_code) do
    currency_name =
      currency_code
      |> Currency.currency_for_code!()
      |> Map.get(:name, "UNKNOWN")

    "#{currency_name} - #{currency_code}"
  end

  def all_currencies do
    not_real_currencies = [:XAG, :XAU, :XXX]

    for currency <-
          Enum.filter(Money.known_current_currencies(), fn currency ->
            currency not in not_real_currencies
          end),
        do: {localize_currency(currency), currency}
  end
end
