defmodule HamsterTravelWeb.CldrTest do
  use ExUnit.Case
  alias HamsterTravelWeb.Cldr

  describe "currency options" do
    test "puts preferred currencies before major currencies and the rest without duplicates" do
      options = Cldr.all_currencies(["THB", :USD, "EUR", "THB", nil, "INVALID"])
      currencies = Enum.map(options, &elem(&1, 1))

      assert Enum.take(currencies, 5) == [:THB, :USD, :EUR, :GBP, :CHF]
      assert currencies == Enum.uniq(currencies)
      assert MapSet.new(currencies) == MapSet.new(Cldr.all_currencies(), &elem(&1, 1))
    end

    test "prioritizes home currency, then visited countries, then other major currencies" do
      trip = %HamsterTravel.Planning.Trip{
        countries: [
          %HamsterTravel.Geo.Country{iso: "TH", currency_code: "THB"},
          %HamsterTravel.Geo.Country{iso: "FR", currency_code: "EUR"},
          %HamsterTravel.Geo.Country{iso: "DE", currency_code: "EUR"},
          %HamsterTravel.Geo.Country{iso: "GB", currency_code: "GBP"}
        ]
      }

      currencies = Enum.map(Cldr.trip_currencies(trip, "GBP"), &elem(&1, 1))

      assert Enum.take(currencies, 5) == [:GBP, :THB, :EUR, :USD, :CHF]
      assert currencies == Enum.uniq(currencies)
    end

    test "includes a visited country's shared currency even when it is normally filtered out" do
      trip = %HamsterTravel.Planning.Trip{
        countries: [%HamsterTravel.Geo.Country{iso: "SN", currency_code: "XOF"}]
      }

      assert Enum.take(Cldr.trip_currencies(trip, "EUR"), 3) == [EUR: :EUR, XOF: :XOF, USD: :USD]
    end

    test "falls back to EUR for a new trip without a home currency" do
      assert Cldr.trip_currencies(%HamsterTravel.Planning.Trip{}, nil) == Cldr.all_currencies()
    end
  end

  describe "format_time/1" do
    test "formats naive datetime to HH:mm format" do
      naive_datetime = ~N[2023-12-25 12:34:56]

      assert Cldr.format_time(naive_datetime) == "12:34"
    end

    test "formats noon correctly" do
      naive_datetime = ~N[2023-12-25 12:00:00]

      assert Cldr.format_time(naive_datetime) == "12:00"
    end

    test "formats midnight correctly" do
      naive_datetime = ~N[2023-12-25 00:00:00]

      assert Cldr.format_time(naive_datetime) == "00:00"
    end

    test "formats single digit minutes with leading zero" do
      naive_datetime = ~N[2023-12-25 09:05:00]

      assert Cldr.format_time(naive_datetime) == "09:05"
    end

    test "returns nil when naive_datetime is nil" do
      assert Cldr.format_time(nil) == nil
    end
  end

  describe "convert_money_for_display/2" do
    test "returns original money when currencies match" do
      money = Money.new(:USD, 100)
      display_currency = "USD"

      {display_money, original_money, is_converted} =
        Cldr.convert_money_for_display(money, display_currency)

      assert display_money == money
      assert original_money == money
      assert is_converted == false
    end

    test "converts money when currencies differ and conversion succeeds" do
      money = Money.new(:USD, 100)
      display_currency = "EUR"

      {display_money, original_money, is_converted} =
        Cldr.convert_money_for_display(money, display_currency)

      # Should return converted money
      assert display_money.currency == :EUR
      # Assuming exchange rate is not 1:1
      assert display_money.amount != money.amount

      # Original money unchanged
      assert original_money == money
      assert original_money.currency == :USD

      # Should be marked as converted
      assert is_converted == true
    end

    test "handles conversion error gracefully" do
      money = Money.new(:USD, 100)
      display_currency = "INVALID"

      {display_money, original_money, is_converted} =
        Cldr.convert_money_for_display(money, display_currency)

      # Should fallback to original money when conversion fails
      assert display_money == money
      assert original_money == money
      assert is_converted == false
    end

    test "preserves original amount precision" do
      money = Money.new(:USD, "123.45")
      display_currency = "USD"

      {display_money, original_money, is_converted} =
        Cldr.convert_money_for_display(money, display_currency)

      assert Money.to_string(display_money) == Money.to_string(money)
      assert Money.to_string(original_money) == Money.to_string(money)
      assert is_converted == false
    end

    test "handles zero amounts correctly" do
      money = Money.new(:USD, 0)
      display_currency = "EUR"

      {display_money, original_money, is_converted} =
        Cldr.convert_money_for_display(money, display_currency)

      # Even zero amounts should be converted if currencies differ
      assert display_money.currency == :EUR
      assert Decimal.equal?(display_money.amount, Decimal.new(0))
      assert original_money == money
      assert is_converted == true
    end

    test "handles negative amounts correctly" do
      money = Money.new(:USD, -50)
      display_currency = "EUR"

      {display_money, original_money, is_converted} =
        Cldr.convert_money_for_display(money, display_currency)

      # Negative amounts should be converted properly
      assert display_money.currency == :EUR
      # Should remain negative
      assert Decimal.negative?(display_money.amount)
      assert original_money == money
      assert is_converted == true
    end
  end
end
