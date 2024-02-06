defmodule HamsterTravelWeb.Cldr do
  @moduledoc """
  Locale data
  """
  use Cldr,
    default_locale: "en",
    locales: ["en", "ru"],
    providers: [Cldr.Number, Cldr.Currency, Cldr.Calendar, Cldr.DateTime, Money]

  def format_money(val, currency) do
    HamsterTravelWeb.Cldr.Number.to_string!(val,
      format: :currency,
      currency: currency
    )
  end

  def date_with_weekday(date) do
    HamsterTravelWeb.Cldr.Date.to_string!(date, format: "dd.MM.yyyy EEEE")
  end

  def localize_currency(currency_code) do
    currency_name =
      currency_code
      |> HamsterTravelWeb.Cldr.Currency.currency_for_code!()
      |> Map.get(:name, "UNKNOWN")

    "#{currency_name} - #{currency_code}"
  end
end
