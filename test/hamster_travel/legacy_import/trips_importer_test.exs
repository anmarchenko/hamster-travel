defmodule HamsterTravel.LegacyImport.TripsImporterTest do
  use HamsterTravel.DataCase

  alias HamsterTravel.LegacyImport.TripsImporter
  alias HamsterTravel.Planning.{Activity, BudgetCategory, DayExpense, Expense, Trip}

  import HamsterTravel.AccountsFixtures

  test "imports HUF minor-unit payloads as whole forints" do
    user = user_fixture()

    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "hamster_travel_import_test_#{System.unique_integer([:positive])}"
      )

    bundle_dir = Path.join(tmp_dir, "bundle")

    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    File.mkdir_p!(bundle_dir)

    File.write!(
      Path.join(bundle_dir, "trips.jsonl"),
      Jason.encode!(%{
        trip_ref: "legacy_trip_huf",
        legacy_trip_id: 1,
        name: "Imported HUF trip",
        status: "2_finished",
        dates_unknown: false,
        start_date: "2021-09-07",
        end_date: "2021-09-14",
        duration: 8,
        currency: "HUF",
        people_count: 3,
        private: false,
        author_legacy_user_id: 1,
        participant_legacy_user_ids: [],
        destinations: [],
        accommodations: [],
        transfers: [],
        activities: [
          %{
            legacy_activity_id: 1,
            day_index: 0,
            name: "Matthias Church",
            priority: 2,
            expense: %{name: "Matthias Church", amount_cents: 4000, currency: "HUF"}
          }
        ],
        day_expenses: [
          %{
            legacy_day_expense_id: 1,
            name: "Public transport",
            day_index: 0,
            expense: %{name: "Public transport", amount_cents: 9000, currency: "HUF"}
          }
        ],
        food_expense: %{
          price_per_day_cents: 6145,
          days_count: 7,
          people_count: 3,
          expense: %{name: "Legacy food expense", amount_cents: 129_045, currency: "HUF"}
        },
        notes: []
      }) <> "\n"
    )

    user_map_file = Path.join(tmp_dir, "user_map.json")
    File.write!(user_map_file, Jason.encode!(%{"1" => user.email}))

    assert {:ok, %{imported: 1, failed: 0}} =
             TripsImporter.import(
               bundle_dir: bundle_dir,
               user_map_file: user_map_file,
               purge_existing: true
             )

    trip = Repo.get_by!(Trip, name: "Imported HUF trip")

    activity =
      Repo.one!(
        from a in Activity,
          join: e in assoc(a, :expense),
          where: a.trip_id == ^trip.id and a.name == "Matthias Church",
          preload: [expense: e]
      )

    day_expense =
      Repo.one!(
        from d in DayExpense,
          join: e in assoc(d, :expense),
          where: d.trip_id == ^trip.id and d.name == "Public transport",
          preload: [expense: e]
      )

    food_category =
      Repo.one!(
        from category in BudgetCategory,
          join: estimate in Expense,
          on:
            estimate.budget_category_id == category.id and
              estimate.budget_role == "category_estimate",
          where: category.trip_id == ^trip.id and category.kind == "food",
          preload: [estimated_expense: estimate, food_setting: []]
      )

    assert activity.expense.price == Money.new(:HUF, "4000")
    assert day_expense.expense.price == Money.new(:HUF, "9000")
    assert food_category.food_setting.price_per_day == Money.new(:HUF, "6145")
    assert food_category.estimated_expense.price == Money.new(:HUF, "129045")
  end
end
