defmodule HamsterTravel.PlanningTest do
  use HamsterTravel.DataCase

  alias HamsterTravel.Planning

  describe "trips" do
    alias HamsterTravel.Planning.Trip

    import HamsterTravel.PlanningFixtures

    @invalid_attrs %{currency: nil, dates_unknown: nil, duration: nil, end_date: nil, name: nil, people_count: nil, private: nil, start_date: nil, status: nil}

    test "list_trips/0 returns all trips" do
      trip = trip_fixture()
      assert Planning.list_trips() == [trip]
    end

    test "get_trip!/1 returns the trip with given id" do
      trip = trip_fixture()
      assert Planning.get_trip!(trip.id) == trip
    end

    test "create_trip/1 with valid data creates a trip" do
      valid_attrs = %{currency: "some currency", dates_unknown: true, duration: 42, end_date: ~D[2023-06-12], name: "some name", people_count: 42, private: true, start_date: ~D[2023-06-12], status: "some status"}

      assert {:ok, %Trip{} = trip} = Planning.create_trip(valid_attrs)
      assert trip.currency == "some currency"
      assert trip.dates_unknown == true
      assert trip.duration == 42
      assert trip.end_date == ~D[2023-06-12]
      assert trip.name == "some name"
      assert trip.people_count == 42
      assert trip.private == true
      assert trip.start_date == ~D[2023-06-12]
      assert trip.status == "some status"
    end

    test "create_trip/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Planning.create_trip(@invalid_attrs)
    end

    test "update_trip/2 with valid data updates the trip" do
      trip = trip_fixture()
      update_attrs = %{currency: "some updated currency", dates_unknown: false, duration: 43, end_date: ~D[2023-06-13], name: "some updated name", people_count: 43, private: false, start_date: ~D[2023-06-13], status: "some updated status"}

      assert {:ok, %Trip{} = trip} = Planning.update_trip(trip, update_attrs)
      assert trip.currency == "some updated currency"
      assert trip.dates_unknown == false
      assert trip.duration == 43
      assert trip.end_date == ~D[2023-06-13]
      assert trip.name == "some updated name"
      assert trip.people_count == 43
      assert trip.private == false
      assert trip.start_date == ~D[2023-06-13]
      assert trip.status == "some updated status"
    end

    test "update_trip/2 with invalid data returns error changeset" do
      trip = trip_fixture()
      assert {:error, %Ecto.Changeset{}} = Planning.update_trip(trip, @invalid_attrs)
      assert trip == Planning.get_trip!(trip.id)
    end

    test "delete_trip/1 deletes the trip" do
      trip = trip_fixture()
      assert {:ok, %Trip{}} = Planning.delete_trip(trip)
      assert_raise Ecto.NoResultsError, fn -> Planning.get_trip!(trip.id) end
    end

    test "change_trip/1 returns a trip changeset" do
      trip = trip_fixture()
      assert %Ecto.Changeset{} = Planning.change_trip(trip)
    end
  end
end
