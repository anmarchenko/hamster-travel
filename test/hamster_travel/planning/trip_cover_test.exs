defmodule HamsterTravel.Planning.TripCoverTest do
  use HamsterTravel.DataCase

  import HamsterTravel.PlanningFixtures

  alias HamsterTravel.Planning.TripCover

  test "validates allowed file extensions" do
    trip = trip_fixture()

    assert TripCover.validate({%{file_name: "cover.jpg"}, trip})
    assert TripCover.validate({%{file_name: "cover.webp"}, trip})
    refute TripCover.validate({%{file_name: "cover.txt"}, trip})
  end

  test "builds the storage directory per trip" do
    trip = trip_fixture()

    assert TripCover.storage_dir(:hero, {"cover.jpg", trip}) ==
             "uploads/trips/#{trip.id}/cover"
  end

  test "present?/1 returns true only for covers with non-empty file names" do
    assert TripCover.present?(%{file_name: "cover.jpg"})
    assert TripCover.present?(%{"file_name" => "cover.jpg"})
    assert TripCover.present?("cover.jpg")
    refute TripCover.present?(%{file_name: nil})
    refute TripCover.present?(%{file_name: ""})
    refute TripCover.present?(nil)
  end
end
