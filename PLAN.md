# Plan: Day-level "other expenses" in Activities tab

## Goal
Add a new day-scoped entity for expenses that are not tied to an activity (e.g., transport card on day 3), with one `Expense` per item. It must be create/edit/delete in the Activities tab, and be draggable to reorder within a day and move between days (like activities).

## Proposed name
Use `DayExpense` (schema/table: `day_expenses`). It conveys a day-scoped item without implying an activity. 

## Step-by-step implementation plan

### 1) Study existing activity flow end-to-end
- Read the activity Ecto schema, context functions, and preloads in `lib/hamster_travel/planning/activity.ex` and `lib/hamster_travel/planning.ex` to mirror ordering/drag behavior.
- Review LiveView UI pieces in `lib/hamster_travel_web/live/planning_live/show_trip.ex` and activity components in `lib/hamster_travel_web/live/planning_live/components/`.
- Inspect drag/drop hook in `assets/js/activity_drag_drop.js` to replicate in a new hook for day expenses.

### 2) Database schema changes
- Add a new migration to create `day_expenses` table with:
  - `name` (string, required)
  - `day_index` (integer, required)
  - `rank` (integer, for ordering)
  - `trip_id` (binary_id, required, FK to trips)
  - timestamps
- Add `day_expense_id` (nullable FK) to `expenses` table, with index.
- Add indexes on `day_expenses` for `trip_id` and `trip_id, day_index`.

### 3) Ecto schema + association updates
- Create `lib/hamster_travel/planning/day_expense.ex`:
  - Fields: `name`, `day_index`, `rank`, `position` virtual.
  - `belongs_to :trip, HamsterTravel.Planning.Trip`.
  - `has_one :expense, HamsterTravel.Planning.Expense`.
  - `changeset/2` using `EctoOrdered.set_order(:position, :rank, [:trip_id, :day_index])`, `cast_assoc(:expense)` and `validate_required([:name, :day_index, :trip_id])`.
- Update `lib/hamster_travel/planning/expense.ex` with `belongs_to :day_expense` and include `:day_expense_id` in `cast`.
- Update `lib/hamster_travel/planning/trip.ex` with `has_many :day_expenses, HamsterTravel.Planning.DayExpense`.

### 4) Planning context API
Mirror activity functions in `lib/hamster_travel/planning.ex`:
- `get_day_expense!/1`, `list_day_expenses/1`, `create_day_expense/2`, `update_day_expense/2`, `delete_day_expense/1`, `new_day_expense/3`, `change_day_expense/2`.
- `move_day_expense_to_day/5` and `reorder_day_expense/4` to support drag/drop (authorize, validate trip membership, validate day index).
- `day_expenses_for_day/2` for day-specific ordering.
- Add preloading helper for day expenses (preload `:expense`).
- Include `day_expenses: :expense` in `single_trip_preloading/1`.
- Update `preload_entity_associations/2`, `get_entities_key/1`, and `maybe_recalculate_budget/3` in `show_trip.ex` to handle `:day_expense`.

### 5) LiveView UI and components
Add a parallel set of components similar to activities:
- New components:
  - `lib/hamster_travel_web/live/planning_live/components/day_expense.ex` (display + edit/delete).
  - `lib/hamster_travel_web/live/planning_live/components/day_expense_form.ex` (fields: name + expense price).
  - `lib/hamster_travel_web/live/planning_live/components/day_expense_new.ex` ("New expense" element styled exactly like "New activity" element).
- In `show_trip.ex`:
  - Add list + new button in `tab_activity` for each day (above activities list).
  - Add "outside" section handling for `day_expenses_outside/1` (day_index >= duration).
  - Add helper to find `day_expense` in trip for drag events.
  - Wire new events to `handle_event/3` for "move_day_expense" and "reorder_day_expense".
  - Extend the "start adding" / "finish adding" handling with a new component type name (e.g., `"day_expense"`).
  - Update budgeting logic to recalc when day expenses change.
- Ensure displayed money uses `money_display` with `display_currency` like activities.
- Ensure text uses `gettext/1`.

### 6) Drag and drop hook for day expenses
- Create `assets/js/day_expense_drag_drop.js` modeled on `activity_drag_drop.js`:
  - make sure that phx-hook for expenses and activities do not conflict - you are allowed to unite them in one phx-hook object if needed
  - Use unique group name (e.g., `day-expenses`) and `data-day-expense-drop-zone` + `data-day-expense-id`.
  - Make sure that expenses drop zone does not conflict with activities drop zone
  - Emit LiveView events `move_day_expense` and `reorder_day_expense` with `day_expense_id`, `new_day_index`, `position`.
- Register the hook in `assets/js/app.js`.

### 7) Tests and fixtures
- Add fixture helper in `test/support/fixtures/planning_fixtures.ex` for `day_expense_fixture/1` (with nested expense).
- Add/extend context tests in `test/hamster_travel/planning_test.exs`:
  - CRUD, validations, `new_day_expense/2`, and `day_expenses_for_day/2` ordering.
  - `move_day_expense_to_day/5` and `reorder_day_expense/4` coverage similar to activities.
- Add LiveView tests in `test/hamster_travel_web/live/planning_live/show_trip_test.exs`:
  - Can open form in Activities tab, create day expense, and see it rendered.
  - Optional drag/drop not testable here; focus on events and rendering.

### 8) i18n updates
- Add new strings in the UI (labels, button text, confirmation text) using `gettext/1` and run `mix gettext` if required for catalog updates.

### 9) Manual verification checklist
- In Activities tab:
  - Add day expense, edit, delete; verify expense price saved.
  - Drag within day reorders; drag to another day updates day index.
  - "Outside" section shows items scheduled past duration.
  - Budget updates when day expenses change.
- Confirm `Expense` entries are created with `trip_id` and `day_expense_id` and appear in overall budget.
