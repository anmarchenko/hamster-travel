defmodule HamsterTravelWeb.Planning.ShowTripParticipantsTest do
  use HamsterTravelWeb.ConnCase

  import HamsterTravel.AccountsFixtures
  import HamsterTravel.PlanningFixtures
  import Phoenix.LiveViewTest

  alias HamsterTravel.Planning
  alias HamsterTravel.Social

  describe "trip participants on show page" do
    test "author can add participant and add form hides when all friends are in trip", %{
      conn: conn
    } do
      author = user_fixture()
      friend = user_fixture()
      {:ok, _} = Social.add_friends(author.id, friend.id)
      trip = trip_fixture(author, %{})
      conn = log_in_user(conn, author)

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}")
      assert has_element?(view, "#trip-open-invite-modal")

      view
      |> element("#trip-open-invite-modal")
      |> render_click()

      assert has_element?(view, "#trip-invite-friend-#{friend.id}")

      view
      |> element("#trip-invite-friend-#{friend.id}")
      |> render_click()

      trip = Planning.get_trip!(trip.id)
      assert Enum.map(trip.trip_participants, & &1.user_id) == [friend.id]
      refute has_element?(view, "#trip-invite-participant-modal")
      refute has_element?(view, "#trip-open-invite-modal")
    end

    test "participant can add another author's friend", %{conn: conn} do
      author = user_fixture()
      participant = user_fixture()
      friend = user_fixture()
      {:ok, _} = Social.add_friends(author.id, participant.id)
      {:ok, _} = Social.add_friends(author.id, friend.id)

      trip = trip_fixture(author, %{})
      {:ok, trip} = Planning.add_trip_participant(trip, author, participant.id)
      conn = log_in_user(conn, participant)

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}")
      assert has_element?(view, "#trip-open-invite-modal")

      view
      |> element("#trip-open-invite-modal")
      |> render_click()

      assert has_element?(view, "#trip-invite-friend-#{friend.id}")
      assert render(view) =~ friend.name

      view
      |> element("#trip-invite-friend-#{friend.id}")
      |> render_click()

      trip = Planning.get_trip!(trip.id)

      assert Enum.sort(Enum.map(trip.trip_participants, & &1.user_id)) ==
               Enum.sort([participant.id, friend.id])
    end

    test "non-participant friend does not see participant add form", %{conn: conn} do
      author = user_fixture()
      participant = user_fixture()
      non_participant_friend = user_fixture()
      {:ok, _} = Social.add_friends(author.id, participant.id)
      {:ok, _} = Social.add_friends(author.id, non_participant_friend.id)

      trip = trip_fixture(author, %{})
      {:ok, _} = Planning.add_trip_participant(trip, author, participant.id)
      conn = log_in_user(conn, non_participant_friend)

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}")
      refute has_element?(view, "#trip-open-invite-modal")
    end

    test "author can remove any participant", %{conn: conn} do
      author = user_fixture()
      participant = user_fixture()
      {:ok, _} = Social.add_friends(author.id, participant.id)
      trip = trip_fixture(author, %{})
      {:ok, trip} = Planning.add_trip_participant(trip, author, participant.id)
      conn = log_in_user(conn, author)

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}")

      assert has_element?(
               view,
               "#trip-participant-#{participant.id} [phx-click='remove_trip_participant']"
             )

      view
      |> element("#trip-participant-#{participant.id} [phx-click='remove_trip_participant']")
      |> render_click()

      trip = Planning.get_trip!(trip.id)
      assert trip.trip_participants == []
    end

    test "participant can remove themselves but not other participants", %{conn: conn} do
      author = user_fixture()
      participant = user_fixture()
      other_participant = user_fixture()
      {:ok, _} = Social.add_friends(author.id, participant.id)
      {:ok, _} = Social.add_friends(author.id, other_participant.id)
      trip = trip_fixture(author, %{})
      {:ok, trip} = Planning.add_trip_participant(trip, author, participant.id)
      {:ok, trip} = Planning.add_trip_participant(trip, author, other_participant.id)
      conn = log_in_user(conn, participant)

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}")

      assert has_element?(
               view,
               "#trip-participant-#{participant.id} [phx-click='remove_trip_participant']"
             )

      refute has_element?(
               view,
               "#trip-participant-#{other_participant.id} [phx-click='remove_trip_participant']"
             )

      view
      |> element("#trip-participant-#{participant.id} [phx-click='remove_trip_participant']")
      |> render_click()

      trip = Planning.get_trip!(trip.id)

      refute Enum.any?(trip.trip_participants, &(&1.user_id == participant.id))
      assert Enum.any?(trip.trip_participants, &(&1.user_id == other_participant.id))
    end
  end
end
