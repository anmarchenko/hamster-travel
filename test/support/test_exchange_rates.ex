defmodule HamsterTravel.TestExchangeRates do
  @moduledoc """
  Test exchange rates module that provides fixed exchange rates for testing.

  Implements the Money.ExchangeRates behaviour to provide predictable
  exchange rates for EUR, USD, and GBP in tests.
  """

  @behaviour Money.ExchangeRates

  # Fixed exchange rates for testing (base currency: EUR)
  @fixed_rates %{
    # Base currency
    EUR: Decimal.new("1.0"),
    # 1 EUR = 1.10 USD
    USD: Decimal.new("1.10"),
    # 1 EUR = 0.85 GBP
    GBP: Decimal.new("0.85")
  }

  @impl Money.ExchangeRates
  def get_latest_rates(_config) do
    {:ok, @fixed_rates}
  end

  @impl Money.ExchangeRates
  def get_historic_rates(_date, _config) do
    {:ok, @fixed_rates}
  end

  @impl Money.ExchangeRates
  def decode_rates(body) when is_map(body) do
    body
  end

  def decode_rates(_body) do
    @fixed_rates
  end

  @impl Money.ExchangeRates
  def init(config) do
    config
  end
end
