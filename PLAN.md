# Activities Feature Plan

Goal: add Activity entities to the planning app, including data model, UI, drag-and-drop day moves and intra-day reordering (using EctoOrdered), with full test coverage at each step.

## Step 1: Data model + Planning context API for activities (CRUD + list + preload)

Scope:
- Add `activities` table with fields: `trip_id` (FK), `day_index` (int), `name` (string), `priority` (int 1-3), `link` (string, optional), `address` (string, optional), `description` (text, rich HTML), `rank` (int for ordering), `inserted_at`, `updated_at`.
- Update `expenses` table and schema to link to activities (`activity_id`) and ensure `trip_id` is set on nested expense attrs (mirror accommodations/transfers).
- Add `HamsterTravel.Planning.Activity` schema + changeset with validations (required: `name`, `day_index`, `trip_id`, `priority`; `day_index >= 0`; `priority` in 1..3; optional `link/address/description`; cast_assoc `:expense`; use EctoOrdered to manage `rank` scoped per day).
- Wire into `HamsterTravel.Planning` context: `get_activity!/1`, `list_activities/1`, `create_activity/2`, `update_activity/2`, `delete_activity/1`, `new_activity/2`, `change_activity/2`, `activities_for_day/2` (ordered by `position`), `activity_preloading/1`.
- Update `Trip` schema to `has_many :activities` and `single_trip_preloading/1` to preload activities + expenses.
- Add fixtures: `activity_fixture/1` in `test/support/fixtures/planning_fixtures.ex` (include priority and expense attrs).

Verification (tests must pass):
- Add `describe "activities"` tests in `test/hamster_travel/planning_test.exs` mirroring accommodation/transfer coverage: list, get, create (valid + invalid), update (valid + invalid), delete, change, new, `activities_for_day/2` ordering, expense association persisted, and activity expense has `trip_id` and `activity_id`.
- If you add a new schema-level test module (e.g., `test/hamster_travel/planning/activity_test.exs`), include unit tests for the changeset.
- Run: `mix test test/hamster_travel/planning_test.exs` (and the new activity test file, if created).

LLM prompt for this step:
"""
You are implementing Step 1 of the Activities feature in the Phoenix LiveView app at `/Users/marvin/p/hamster-travel`. Use PLAN.md for reference.

Goal: add the Activity data model + Planning context API with full tests.

Requirements:
- Add a migration for `activities` table with `trip_id`, `day_index`, `name`, `priority` (1-3), `link`, `address`, `description` (text), `rank` (integer), timestamps.
- Add a migration to `expenses` to include `activity_id` FK (nullable).
- Create `lib/hamster_travel/planning/activity.ex` schema + changeset: required `name`, `day_index`, `trip_id`, `priority`; validate `day_index >= 0`; validate `priority` in 1..3; optional `link/address/description`; `has_one :expense` with `cast_assoc`; use `HamsterTravel.EctoOrdered` to manage `rank` scoped per day.
- Update `lib/hamster_travel/planning/expense.ex` to include `belongs_to :activity` and cast `:activity_id`.
- Update `lib/hamster_travel/planning/trip.ex` to `has_many :activities`.
- Update `lib/hamster_travel/planning.ex` preloads (`single_trip_preloading/1`) to preload activities and their expenses, and add context functions: `get_activity!/1`, `list_activities/1`, `create_activity/2`, `update_activity/2`, `delete_activity/1`, `new_activity/2`, `change_activity/2`, `activities_for_day/2` (ordered by rank).
- Ensure `create_activity/2` and `update_activity/2` set nested expense `trip_id` like accommodations/transfers.
- Add `activity_fixture/1` in `test/support/fixtures/planning_fixtures.ex`.
- Add tests in `test/hamster_travel/planning_test.exs` for all Activity API functions, matching the style of existing accommodation/transfer tests, including priority validation, expense association assertions, and `activities_for_day/2` ordering.

Constraints:
- Follow existing patterns from accommodations/transfers.
- Use `gettext/1` only when adding user-visible strings (if any).
- Keep code style consistent with repository.

After changes, run:
- `mix test test/hamster_travel/planning_test.exs` (and any new activity test file if you created one).
"""

## Step 2: Ordering + move APIs (drag/drop backend)

Scope:
- Use `HamsterTravel.EctoOrdered` (mandatory) for activity ordering, scoped per `trip_id` + `day_index` so that ordering is per-day.
- Add context functions to move/reorder activities:
  - `move_activity_to_day(activity, new_day_index, trip, user, position \\ :last)`
  - `reorder_activity(activity, position, trip, user)`
- Validate authorization consistent with `move_transfer_to_day/4` (trip author or friend), day bounds, and that activity belongs to the trip.
- Ensure move updates `day_index` and positions within old and new days without gaps/duplicates.
- Add PubSub events for `[:activity, :updated]` when moving/reordering.

Verification (tests must pass):
- Add tests in `test/hamster_travel/planning_test.exs` for `move_activity_to_day/4-5` and `reorder_activity/4`, covering:
  - move across days, move within same day (no-op), move to first/last day, invalid day index, unauthorized user, activity not in trip.
  - reorder within a day (positions update correctly), and move sets correct position in new day.
- Run: `mix test test/hamster_travel/planning_test.exs`.

LLM prompt for this step:
"""
You are implementing Step 2 of the Activities feature in `/Users/marvin/p/hamster-travel`. Use PLAN.md for reference.

Goal: add backend ordering + move APIs for activities with test coverage.

Requirements:
- Implement per-day ordering for activities using `HamsterTravel.EctoOrdered` (mandatory), scoped to a unique trip+day grouping (e.g., a `day_key` column or equivalent scope field).
- Add context functions in `lib/hamster_travel/planning.ex`:
  - `move_activity_to_day(activity, new_day_index, trip, user, position \\ :last)`
  - `reorder_activity(activity, position, trip, user)`
- Validate day bounds against trip duration, authorization (same rules as transfers), and that the activity belongs to the trip.
- Update activity changeset (if needed) to support position/rank updates.
- Ensure move/reorder emit `[:activity, :updated]` PubSub events and keep ordering consistent.

Testing:
- Add tests in `test/hamster_travel/planning_test.exs` that mirror transfer move tests but for activities, plus explicit reorder assertions.
- Run `mix test test/hamster_travel/planning_test.exs`.
"""

## Step 3: LiveView UI + drag-and-drop integration

Scope:
- Create UI components similar to transfers/accommodations:
  - `lib/hamster_travel_web/live/planning_live/components/activity.ex` (display + edit/delete actions)
  - `lib/hamster_travel_web/live/planning_live/components/activity_form.ex` (create/edit form; use `formatted_text_area` for description)
  - `lib/hamster_travel_web/live/planning_live/components/activity_new.ex` (add-new component)
- Wire components into `planning_components.ex` and `show_trip.ex`:
  - Add `Activity`, `ActivityNew` aliases.
  - Replace `activities={[]}` with `@trip.activities` and pass through `activities_for_day`.
  - Add PubSub handlers for activity create/update/delete and include `:activity` in `preload_entity_associations/2`, `get_entities_key/1`, and `maybe_recalculate_budget/3` if activity expenses should affect budget immediately.
  - Add `:active_activity_adding_component_id` handling and `get_creation_component_info/1` support.
- Add JS drag/drop hook in `assets/js` (e.g., `activity_drag_drop.js`) modeled after packing drag/drop:
  - allow dragging between day columns and reordering within a day.
  - emit `move_activity` and `reorder_activity` events with activity id, new day, and position.
- Add LiveView event handlers in `show_trip.ex` to call the new planning context functions.
- Ensure description renders as sanitized HTML via `formatted_text`.
- Use Petal Components `Rating` for priority in the form and style activity name based on priority in the read-only view (bold/normal/secondary).

Verification (tests must pass):
- Extend `test/hamster_travel_web/live/planning_live/show_trip_test.exs`:
  - Rendering test: activity name, price, and description appear on Activities tab.
  - Form test: “Add activity” opens form and creates activity with expense.
  - Event test: call `render_hook/2` (or similar) to trigger `move_activity` and `reorder_activity` and assert DB updates.
- Run: `mix test test/hamster_travel_web/live/planning_live/show_trip_test.exs`.

LLM prompt for this step:
"""
You are implementing Step 3 of the Activities feature in `/Users/marvin/p/hamster-travel`. Use PLAN.md for reference.

Goal: add LiveView UI and drag-and-drop integration for activities, with tests.

Requirements:
- Create new LiveComponents: `Activity`, `ActivityForm`, `ActivityNew` similar to `Transfer`/`Accommodation` components.
- Display activity fields: name with priority styling (bold if 3, normal if 2, secondary if 1), optional link + address, rich `description` (render using `formatted_text`), and price from associated expense (use `money_display`). Use `live/planning_live/components/old/activity.ex` as a reference for the design of `Activity` component. The design of the new Activity component must be the same as in this old component.
- Add add/edit/delete flows using the form component; use `formatted_text_area` for description input.
- In the Activity form, use the Petal Components `Rating` input for priority selection (1-3).
- Wire into `planning_components.ex` and `show_trip.ex`: pass activities to `tab_activity`, use `Planning.activities_for_day/2`, and hook PubSub events for activity create/update/delete.
- Add drag-and-drop: create `assets/js/activity_drag_drop.js` using SortableJS (like packing) to allow reorder within a day and move between days. Push events `move_activity` and `reorder_activity` with activity id, target day, and position. Register the hook in `assets/js/app.js` and add data attributes to day containers in `tab_activity` markup.
- Add LiveView handlers in `show_trip.ex` to call `Planning.move_activity_to_day/5` and `Planning.reorder_activity/4`.

Testing:
- Update `test/hamster_travel_web/live/planning_live/show_trip_test.exs` to cover activity rendering, add form submission, and LiveView hooks for move/reorder.
- Run `mix test test/hamster_travel_web/live/planning_live/show_trip_test.exs`.
"""

## Step 4: i18n + polish + full test sweep

Scope:
- Add gettext strings for any new labels (e.g., “Add activity”, “Activity details”, “Delete activity”, error flashes).
- Ensure currencies display consistently and that activities affect budget if they have expenses.
- Update any stale references (remove/ignore `components/old/activitiy.ex` if unused).
- Run `mix gettext` only if you added new strings that should be extracted.

Verification (tests must pass):
- Run a full test sweep for confidence: `mix test`.

LLM prompt for this step:
"""
You are implementing Step 4 of the Activities feature in `/Users/marvin/p/hamster-travel`. Use PLAN.md for reference.

Goal: finalize i18n strings, clean up references, and run full tests.

Requirements:
- Add any missing `gettext/1` strings for new UI labels and flash messages.
- Ensure activities affect trip budget when they have expenses, consistent with accommodations/transfers.
- Remove or ignore any obsolete references to `lib/hamster_travel_web/live/planning_live/components/old/activitiy.ex` if unused.
- Run `mix gettext` only if new strings were added and need extraction.

Testing:
- Run `mix test` and confirm all tests pass.
"""
