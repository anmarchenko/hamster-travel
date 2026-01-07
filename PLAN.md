# Notes Feature Plan

## 1) Data model + core context API
- Add a `notes` table migration with fields: `title` (string, required), `text` (text), `day_index` (integer, nullable), `rank` (integer), `trip_id` (binary_id FK), timestamps, plus indexes on `trip_id` and `trip_id, day_index`.
- Create `lib/hamster_travel/planning/note.ex` with `EctoOrdered` ordering on `[:trip_id, :day_index]`, allow `day_index` to be `nil` (unassigned) or `>= 0` when present, and use `:title` required.
- Add `has_many :notes` to `lib/hamster_travel/planning/trip.ex`.
- Extend `lib/hamster_travel/planning.ex`:
  - Alias `Note`.
  - Add `list_notes/1`, `get_note!/1`, `new_note/2`, `change_note/2`, `create_note/2`, `update_note/2`, `delete_note/1`.
  - Preload notes in `single_trip_preloading/1`.
- Add a `note_fixture/1` to `test/support/fixtures/planning_fixtures.ex`.
- Tests: create `test/hamster_travel/planning/notes_test.exs` covering CRUD, validation (required title, optional day_index), and listing behavior.
- Run: `mix test test/hamster_travel/planning/notes_test.exs`.

## 2) Ordering + movement rules
- Add context helpers in `lib/hamster_travel/planning.ex`:
  - `notes_for_day/2` (day-indexed notes sorted by `rank`).
  - `notes_unassigned/1` (notes with `day_index == nil`).
  - `move_note_to_day/5` and `reorder_note/4` mirroring activity/day_expense logic, with validation:
    - note belongs to trip
    - user authorization
    - day_index either `nil` (for unassigned) or in trip duration when moving to a day
- Ensure updates keep ordering stable by using `position` + `rank` within the proper scope.
- Tests: extend `test/hamster_travel/planning/notes_test.exs` with reorder/move cases (between days, into unassigned, invalid day_index, unauthorized user).
- Run: `mix test test/hamster_travel/planning/notes_test.exs`.

## 3) Notes UI components + Activity tab integration
- Add LiveComponents:
  - `lib/hamster_travel_web/live/planning_live/components/note.ex` (display, edit/delete, formatted text rendering).
  - `lib/hamster_travel_web/live/planning_live/components/note_form.ex` (title + formatted text area, hidden day_index).
  - `lib/hamster_travel_web/live/planning_live/components/note_new.ex` (add button + inline form).
- Update `lib/hamster_travel_web/live/planning_live/show_trip.ex`:
  - Add note PubSub handlers.
  - Add note handling to `preload_entity_associations/2`, `get_entities_key/1`, `handle_entity_event/4`, `find_note_in_trip/2`, and active component state helpers.
  - In `tab_activity/1`, render notes per day (only day-bound notes) and include an outside-of-trip toggle section for notes with `day_index >= trip.duration`.
- Tests: update `test/hamster_travel_web/live/planning_live/show_trip_test.exs` to assert notes render on the activities tab (per day and outside toggle), plus add-note form toggling.
- Run: `mix test test/hamster_travel_web/live/planning_live/show_trip_test.exs`.

## 4) Notes tab + navigation + translations
- Add notes tab entry after activities in:
  - `@tabs`, `planning_tabs/1`, and `render_tab/1` in `lib/hamster_travel_web/live/planning_live/show_trip.ex`.
  - Mobile tab navigation in `lib/hamster_travel_web/components/layouts.ex`.
  - `trip_url/2` in `lib/hamster_travel_web/components/core_components.ex`.
- Implement `tab_notes/1` in `lib/hamster_travel_web/live/planning_live/show_trip.ex`:
  - Section for unassigned notes first.
  - Day-by-day notes next.
  - Outside-of-trip toggle for day-bound notes with `day_index >= trip.duration`.
- Add gettext strings for new labels and run `mix gettext` if needed to update `.po` files.
- Tests: extend `test/hamster_travel_web/live/planning_live/show_trip_test.exs` to assert the Notes tab appears in desktop + mobile nav and renders unassigned/day notes.
- Run: `mix test test/hamster_travel_web/live/planning_live/show_trip_test.exs`.

## 5) Drag-and-drop wiring for notes
- Extend `assets/js/activity_drag_drop.js` (or add a new hook) to support note drag/drop:
  - Drop zones for unassigned notes and each day.
  - Push `move_note` and `reorder_note` events with `note_id`, `new_day_index` (or `null`/`outside` handling), and `position`.
- Update `lib/hamster_travel_web/live/planning_live/show_trip.ex` to handle `move_note`/`reorder_note` events and call Planning context functions.
- Ensure unassigned notes can be moved to a day, and day notes can be moved back to unassigned.
- Tests: add LiveView tests that simulate move/reorder events (e.g., `render_hook`) and assert notes change day or order in assigns.
- Run: `mix test test/hamster_travel_web/live/planning_live/show_trip_test.exs`.
