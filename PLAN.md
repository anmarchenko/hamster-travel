# Food Expense Feature Plan

## Goal
Add a trip-level food expense that is not tied to an Activity or a day. All trips must have this expense. Users enter three editable parameters (price per person per day, number of days, number of people) and the total food expense is calculated as:

  price_per_day * number_of_days * number_of_people

The UI should match the existing planning forms and use the same Edit button style.

## Step-by-step plan

1) Decision: creation strategy
- Food expense is required for every trip.
- Create it automatically at trip creation with defaults:
  - `days_count = trip.duration`
  - `people_count = trip.people_count`
  - `price_per_day = 0` (trip currency)
  - `expense.price = 0`
- UI is always present (no “Add food expense” button).

2) Discovery and baseline checks
- Review DayExpense and Expense patterns to reuse the same model + form flow.
- Note how budget is calculated (Planning.calculate_budget/1 uses trip expenses) so food should create an Expense tied to the trip.
- Identify UI placement in `lib/hamster_travel_web/live/planning_live/show_trip.ex` (Activities tab already shows a budget header and an Expenses section).

3) Data model and database migration
- Add a new schema: `lib/hamster_travel/planning/food_expense.ex`.
- Fields:
  - `price_per_day` (Money.Ecto.Composite.Type) for a per-person daily amount in trip currency.
  - `days_count` (integer) and `people_count` (integer).
  - `trip_id` (binary_id).
- Relations:
  - `belongs_to :trip` (Trip).
  - `has_one :expense` (Expense) so it participates in budget calculation.
- Create a migration:
  - Create `food_expenses` table with fields above plus timestamps.
  - Add `food_expense_id` (nullable) to `expenses` table for linkage.
- Update `lib/hamster_travel/planning/expense.ex` to include `belongs_to :food_expense`.
- Update `lib/hamster_travel/planning/trip.ex` to add `has_one :food_expense`.

4) Planning context API
- Add functions in `lib/hamster_travel/planning.ex`:
  - `get_food_expense/1`, `create_food_expense/2`, `update_food_expense/2`, `change_food_expense/2`, `new_food_expense/2`.
- Ensure the FoodExpense changeset:
  - Validates positive integers for `days_count` and `people_count`.
  - Validates `price_per_day` and `trip_id`.
- On create/update, compute total and set `expense.price`:
  - `total = price_per_day * days_count * people_count`.
  - Store total in the associated Expense (with `trip_id` set).
- Preload: update `single_trip_preloading/1` (and any relevant preload helper) to include `food_expense: :expense`.
- PubSub: emit `[:food_expense, :created|:updated|:deleted]` events to align with other entities.
- Budget: ensure food expense is included via the associated `Expense` (no custom budget logic if expense is attached to trip).

5) UI placement and behavior
- Place the food expense block in the Activities tab, near the existing budget header (top of tab), before per-day lists.
- Use an inline summary row for display:
  - Label: "Food".
  - Display total (Money display in trip currency).
  - Show calculation breakdown: "X/day x Y days x Z ppl".
- Edit button should match existing style:
  - Use the pencil icon and the same icon-only button style from DayExpense or Transfer.
  - Keep a delete option if we want to allow removal (optional; match day expense pattern).
- Food expense block is always shown; no "Add" state.

6) LiveComponent + form UI
- Create new components in `lib/hamster_travel_web/live/planning_live/components/`:
  - `food_expense.ex`: handles display vs. edit (similar to DayExpense component).
  - `food_expense_form.ex`: form with three editable fields.
- Form layout:
  - `price_per_day` uses `.money_input` with trip currency.
  - `days_count` and `people_count` use numeric fields.
  - Show a computed total preview (read-only text) to reinforce the formula.
  - Cancel/Save buttons match DayExpenseForm styles (same sizing and placement).

7) ShowTrip wiring
- Assign `food_expense` in `mount/handle_info` (from preloaded trip).
- Add `handle_info` cases for food expense pubsub events (mirrors day expense handlers).
- Add `maybe_recalculate_budget/3` branch for food expenses.
- Render the new component in the Activities tab with `trip`, `food_expense`, and `display_currency`.

8) Tests
- Context tests in `test/hamster_travel/planning_test.exs`:
  - Creating food expense computes total and persists expense.price.
  - Updating one input updates total correctly.
  - Validation for non-positive days/people.
- LiveView tests (where existing planning LiveView tests live):
  - Adding food expense updates the UI and budget display.
  - Editing changes the computed total and display breakdown.

9) Translations and polish
- Add gettext strings for labels and copy in the food expense form and display.
- Run `mix gettext` to extract and merge.
- Verify UI matches existing forms (spacing, button sizes, and edit icon style).

## UI design notes
- Keep styling consistent with existing planning components: inline summary row with a pencil icon for edit, and a compact form with the same button hierarchy (Cancel left, Save right).
- Prefer the DayExpense component styling (icon-only edit, lightweight inline row) for the summary display.
- Use the trip currency and existing Money components so formatting is consistent across budget items.
