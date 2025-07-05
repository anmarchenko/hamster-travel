defmodule HamsterTravelWeb.CldrTest do
  use ExUnit.Case
  alias HamsterTravelWeb.Cldr

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
end
