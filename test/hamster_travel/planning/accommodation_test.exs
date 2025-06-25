defmodule HamsterTravel.Planning.AccommodationTest do
  use HamsterTravel.DataCase

  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.Accommodation

  import HamsterTravel.AccountsFixtures
  import HamsterTravel.PlanningFixtures

  describe "price_per_night/1" do
    test "calculates price per night correctly for multi-night stays" do
      trip = trip_fixture()

      accommodation =
        accommodation_fixture(%{
          trip_id: trip.id,
          start_day: 1,
          end_day: 4,
          expense: %{
            price: Money.new(:EUR, 30_000),
            name: "Hotel booking",
            trip_id: trip.id
          }
        })

      result = Accommodation.price_per_night(accommodation)
      assert Money.equal?(result, Money.new(:EUR, 10_000))
    end

    test "calculates price per night for single night stay (end_day = start_day + 1)" do
      trip = trip_fixture()

      accommodation =
        accommodation_fixture(%{
          trip_id: trip.id,
          start_day: 2,
          end_day: 3,
          expense: %{
            price: Money.new(:EUR, 12_000),
            name: "Hotel booking",
            trip_id: trip.id
          }
        })

      result = Accommodation.price_per_night(accommodation)
      assert Money.equal?(result, Money.new(:EUR, 12_000))
    end

    test "handles same-day accommodation (0 nights, treats as 1 night)" do
      trip = trip_fixture()

      accommodation =
        accommodation_fixture(%{
          trip_id: trip.id,
          start_day: 2,
          end_day: 2,
          expense: %{
            price: Money.new(:EUR, 15_000),
            name: "Day use booking",
            trip_id: trip.id
          }
        })

      result = Accommodation.price_per_night(accommodation)
      assert Money.equal?(result, Money.new(:EUR, 15_000))
    end

    test "returns nil when accommodation has no expense" do
      # Create accommodation without expense
      trip = trip_fixture()

      {:ok, accommodation} =
        Planning.create_accommodation(trip, %{
          name: "Budget Hostel",
          start_day: 1,
          end_day: 3
        })

      result = Accommodation.price_per_night(accommodation)
      assert result == nil
    end

    test "handles zero price expense" do
      trip = trip_fixture()

      accommodation =
        accommodation_fixture(%{
          trip_id: trip.id,
          start_day: 1,
          end_day: 3,
          expense: %{
            price: Money.new(:EUR, 0),
            name: "Free accommodation",
            trip_id: trip.id
          }
        })

      result = Accommodation.price_per_night(accommodation)
      assert Money.equal?(result, Money.new(:EUR, 0))
    end

    test "handles large price amounts" do
      trip = trip_fixture()

      accommodation =
        accommodation_fixture(%{
          trip_id: trip.id,
          start_day: 0,
          end_day: 7,
          expense: %{
            price: Money.new(:EUR, 210_000_000),
            name: "Luxury suite",
            trip_id: trip.id
          }
        })

      result = Accommodation.price_per_night(accommodation)
      assert Money.equal?(result, Money.new(:EUR, 30_000_000))
    end

    test "works with different currencies" do
      trip = trip_fixture()

      accommodation =
        accommodation_fixture(%{
          trip_id: trip.id,
          start_day: 1,
          end_day: 6,
          expense: %{
            price: Money.new(:USD, 50_000),
            name: "Hotel booking",
            trip_id: trip.id
          }
        })

      result = Accommodation.price_per_night(accommodation)
      assert Money.equal?(result, Money.new(:USD, 10_000))
      assert result.currency == :USD
    end

    test "handles fractional division correctly" do
      trip = trip_fixture()

      accommodation =
        accommodation_fixture(%{
          trip_id: trip.id,
          start_day: 0,
          end_day: 3,
          expense: %{
            price: Money.new(:EUR, 10_000),
            name: "Hotel booking",
            trip_id: trip.id
          }
        })

      result = Accommodation.price_per_night(accommodation)
      # 10000 / 3 = 3333.33, Money.div should handle this appropriately
      {:ok, expected} = Money.div(Money.new(:EUR, 10_000), 3)
      assert Money.equal?(result, expected)
    end

    test "handles edge case with start_day 0 and end_day 1" do
      trip = trip_fixture()

      accommodation =
        accommodation_fixture(%{
          trip_id: trip.id,
          start_day: 0,
          end_day: 1,
          expense: %{
            price: Money.new(:EUR, 8_000),
            name: "First night",
            trip_id: trip.id
          }
        })

      result = Accommodation.price_per_night(accommodation)
      assert Money.equal?(result, Money.new(:EUR, 8_000))
    end

    test "handles long stays correctly" do
      trip = trip_fixture()

      accommodation =
        accommodation_fixture(%{
          trip_id: trip.id,
          start_day: 5,
          end_day: 35,
          expense: %{
            price: Money.new(:EUR, 600_000),
            name: "Monthly rental",
            trip_id: trip.id
          }
        })

      result = Accommodation.price_per_night(accommodation)
      assert Money.equal?(result, Money.new(:EUR, 20_000))
    end

    test "returns nil for accommodation struct without required fields" do
      # Test with minimal struct that doesn't match expected pattern
      accommodation = %Accommodation{}
      result = Accommodation.price_per_night(accommodation)
      assert result == nil
    end

    test "returns nil for accommodation with expense but no price field" do
      # This tests the fallback pattern match
      accommodation = %Accommodation{
        start_day: 1,
        end_day: 3,
        expense: %{name: "booking without price"}
      }

      result = Accommodation.price_per_night(accommodation)
      assert result == nil
    end

    test "handles accommodation with preloaded expense" do
      trip = trip_fixture()

      accommodation =
        accommodation_fixture(%{
          trip_id: trip.id,
          start_day: 2,
          end_day: 5,
          expense: %{
            price: Money.new(:EUR, 18_000),
            name: "Hotel booking",
            trip_id: trip.id
          }
        })

      # Reload with preloaded expense to test with actual Expense struct
      accommodation_with_expense =
        Planning.get_accommodation!(accommodation.id) |> Repo.preload(:expense)

      result = Accommodation.price_per_night(accommodation_with_expense)
      assert Money.equal?(result, Money.new(:EUR, 6_000))
    end

    test "handles decimal currencies correctly" do
      trip = trip_fixture()

      accommodation =
        accommodation_fixture(%{
          trip_id: trip.id,
          start_day: 1,
          end_day: 4,
          expense: %{
            price: Money.new(:JPY, 30_000),
            name: "Tokyo hotel",
            trip_id: trip.id
          }
        })

      result = Accommodation.price_per_night(accommodation)
      assert Money.equal?(result, Money.new(:JPY, 10_000))
      assert result.currency == :JPY
    end

    test "preserves currency precision in calculations" do
      trip = trip_fixture()

      # Test with a price that doesn't divide evenly
      accommodation =
        accommodation_fixture(%{
          trip_id: trip.id,
          start_day: 0,
          end_day: 7,
          expense: %{
            price: Money.new(:EUR, 22_222),
            name: "Week stay",
            trip_id: trip.id
          }
        })

      result = Accommodation.price_per_night(accommodation)
      {:ok, expected} = Money.div(Money.new(:EUR, 22_222), 7)
      assert Money.equal?(result, expected)
    end
  end
end
