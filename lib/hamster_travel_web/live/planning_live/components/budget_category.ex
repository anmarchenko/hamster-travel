defmodule HamsterTravelWeb.Planning.BudgetCategory do
  @moduledoc """
  Displays a budget category, its estimate, and its actual expenses.
  """

  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.BudgetCategory, as: Category
  alias HamsterTravel.Planning.Trip
  alias HamsterTravelWeb.Planning.BudgetExpenseSheet

  attr :currency_options, :list, required: true
  attr :category, Category, required: true
  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :display_currency, :string, required: true
  attr :current_user, HamsterTravel.Accounts.User, default: nil
  attr :can_edit, :boolean, default: false
  attr :edit, :boolean, default: false

  @impl true
  def render(%{edit: true} = assigns) do
    ~H"""
    <div id={"budget-category-#{@category.id}"}>
      <.live_component
        module={HamsterTravelWeb.Planning.BudgetCategoryForm}
        id={"budget-category-form-#{@category.id}"}
        action={:edit}
        category={@category}
        trip={@trip}
        currency_options={@currency_options}
        can_edit={@can_edit}
        on_finish={fn -> send(self(), :close_form) end}
      />
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div
      id={"budget-category-#{@category.id}"}
      class="max-w-3xl py-1 min-[1920px]:max-w-6xl"
    >
      <div class="flex w-full items-center gap-2 py-1.5 2xl:text-lg">
        <span class="flex min-w-0 flex-1 items-center gap-1.5">
          <span class="min-w-0 truncate font-medium">
            {category_label(@category)}
          </span>
          <.edit_delete_buttons
            :if={@can_edit}
            edit_target={@myself}
            delete_target={@myself}
            show_delete={!Category.food?(@category)}
            delete_confirm={
              gettext(
                "Are you sure you want to delete category \"%{name}\" and all its actual expenses?",
                name: @category.name
              )
            }
          />
          <button
            :if={
              @can_edit &&
                (@trip.status == Trip.finished() || Enum.any?(@category.actual_expenses))
            }
            type="button"
            phx-click="recalculate"
            phx-target={@myself}
            title={gettext("Set estimate to actual expenses total")}
            aria-label={gettext("Set estimate to actual expenses total")}
            class="inline-flex h-5 w-5 shrink-0 items-center justify-center text-zinc-400 transition-colors hover:text-primary-600 dark:hover:text-primary-300"
          >
            <.icon name="hero-arrow-path" class="h-4 w-4" />
          </button>
        </span>
        <div class="ml-auto flex shrink-0 justify-end sm:w-44">
          <.money_display
            money={@category.estimated_expense.price}
            display_currency={@display_currency}
            class="text-right text-base font-normal tabular-nums text-zinc-500 dark:text-zinc-400 2xl:text-lg"
          />
        </div>
      </div>

      <div
        :if={
          @category.food_setting &&
            @category.food_setting.calculation_mode == "per_day"
        }
        class="ml-4 border-l border-zinc-200 py-1 pl-4 text-sm text-zinc-500 dark:border-zinc-700 dark:text-zinc-400"
      >
        <.money_display
          money={@category.food_setting.price_per_day}
          display_currency={@display_currency}
          class="inline-flex"
        />
        {gettext("per day")} x {@category.food_setting.days_count} {ngettext(
          "day",
          "days",
          @category.food_setting.days_count
        )} x {@category.food_setting.people_count} {ngettext(
          "person",
          "people",
          @category.food_setting.people_count
        )}
      </div>

      <details
        :if={@can_edit || Enum.any?(@category.actual_expenses)}
        id={"budget-actual-expenses-#{@category.id}"}
        phx-mounted={JS.ignore_attributes("open")}
        class="group ml-4 max-w-3xl border-l border-zinc-200 py-1 pl-4 dark:border-zinc-700 min-[1920px]:max-w-6xl"
      >
        <summary
          aria-label={gettext("Actual expenses for %{category}", category: category_label(@category))}
          data-offline-local
          class="flex w-fit cursor-pointer list-none items-center gap-1.5 rounded-sm py-1 text-xs font-medium focus-visible:outline-primary-500 [&::-webkit-details-marker]:hidden [@media(pointer:coarse)]:min-h-[44px]"
        >
          <.icon name="hero-chevron-right" class="h-3.5 w-3.5 group-open:rotate-90" />
          <span>{gettext("Actual expenses")}</span>
          <span class="hidden text-zinc-500 group-open:inline dark:text-zinc-400">
            · {@display_currency}
          </span>
        </summary>
        <div
          id={"budget-expense-sheet-#{@category.id}"}
          phx-hook="BudgetExpenseSheet"
          phx-target={@myself}
          phx-update="ignore"
          data-snapshot={
            Jason.encode!(BudgetExpenseSheet.snapshot(@category, @display_currency, @can_edit))
          }
          data-labels={Jason.encode!(BudgetExpenseSheet.labels())}
          data-currencies={
            Jason.encode!(Enum.map(@currency_options, fn {_, value} -> to_string(value) end))
          }
          class="budget-expense-sheet mt-1"
        >
          <table
            role="grid"
            aria-label={
              gettext("Actual expenses for %{category}", category: category_label(@category))
            }
            data-sheet-grid
          >
          </table>
          <div
            data-sheet-toolbar
            class="mt-1 flex flex-wrap items-center gap-2 text-xs text-zinc-600 dark:text-zinc-400"
          >
            <span data-sheet-selection aria-live="polite"></span>
            <button
              type="button"
              data-sheet-edit
              data-edit-label={gettext("Edit")}
              class="budget-sheet-action"
              hidden
            >
              {gettext("Edit")}
            </button>
            <button type="button" data-sheet-delete class="budget-sheet-action" hidden>
              {gettext("Delete")}
            </button>
            <div data-sheet-editor class="flex-wrap items-center gap-2 [&:not([hidden])]:flex" hidden>
              <select
                data-sheet-edit-currency
                aria-label={gettext("Currency")}
                class="budget-sheet-action budget-sheet-native-currency bg-transparent"
              ></select>
              <button
                type="button"
                data-sheet-edit-currency-button
                aria-haspopup="dialog"
                class="budget-sheet-action budget-sheet-mobile-currency items-center gap-1"
              >
                <span class="sr-only">{gettext("Currency")}</span>
                <span data-sheet-currency-code></span>
                <span aria-hidden="true"><.icon name="hero-chevron-down" class="h-3.5 w-3.5" /></span>
              </button>
              <button
                type="button"
                data-sheet-save
                aria-label={gettext("Save")}
                class="budget-sheet-action"
              >
                <span class="budget-sheet-edit-label">{gettext("Save")}</span>
                <span class="budget-sheet-edit-icon" aria-hidden="true">
                  <.icon name="hero-check" class="h-5 w-5" />
                </span>
              </button>
              <button
                type="button"
                data-sheet-cancel
                aria-label={gettext("Cancel")}
                class="budget-sheet-action"
              >
                <span class="budget-sheet-edit-label">{gettext("Cancel")}</span>
                <span class="budget-sheet-edit-icon" aria-hidden="true">
                  <.icon name="hero-x-mark" class="h-5 w-5" />
                </span>
              </button>
            </div>
          </div>
          <div data-sheet-paste hidden class="mt-2 text-sm">
            <div class="flex flex-wrap items-center gap-2">
              <label for={"budget-sheet-paste-currency-#{@category.id}"}>
                {gettext("Currency for pasted expenses")}
              </label>
              <select
                id={"budget-sheet-paste-currency-#{@category.id}"}
                data-sheet-paste-currency
                class="budget-sheet-native-currency rounded border border-zinc-300 bg-transparent text-sm dark:border-zinc-600"
              ></select>
              <button
                type="button"
                data-sheet-paste-currency-button
                aria-haspopup="dialog"
                class="budget-sheet-action budget-sheet-mobile-currency items-center gap-1"
              >
                <span class="sr-only">{gettext("Currency for pasted expenses")}</span>
                <span data-sheet-currency-code></span>
                <span aria-hidden="true"><.icon name="hero-chevron-down" class="h-3.5 w-3.5" /></span>
              </button>
            </div>
            <p data-sheet-paste-count class="my-1 text-xs"></p>
            <button type="button" data-sheet-paste-save class="budget-sheet-action">{gettext(
              "Add expenses"
            )}</button>
            <button type="button" data-sheet-paste-cancel class="budget-sheet-action">{gettext(
              "Cancel"
            )}</button>
          </div>
          <dialog
            data-sheet-currency-picker
            aria-labelledby={"budget-sheet-currency-title-#{@category.id}"}
            class="budget-sheet-currency-picker"
          >
            <div class="flex items-center justify-between gap-2">
              <h2 id={"budget-sheet-currency-title-#{@category.id}"} class="font-medium">
                {gettext("Currency")}
              </h2>
              <button
                type="button"
                data-sheet-currency-close
                aria-label={gettext("Close")}
                class="budget-sheet-action"
                autofocus
              >
                <span aria-hidden="true"><.icon name="hero-x-mark" class="h-5 w-5 align-middle" /></span>
              </button>
            </div>
            <input
              type="search"
              data-sheet-currency-search
              aria-label={gettext("Search currency codes")}
              placeholder={gettext("Search currency codes")}
              autocomplete="off"
              class="min-w-0 rounded border-zinc-300 bg-transparent text-base dark:border-zinc-600"
            />
            <div data-sheet-currency-options class="min-h-0 overflow-y-auto overscroll-contain"></div>
            <p data-sheet-currency-empty class="text-sm text-zinc-600 dark:text-zinc-400" hidden>
              {gettext("No matching currencies")}
            </p>
          </dialog>
          <p
            data-sheet-status
            role="status"
            class="text-xs text-zinc-600 dark:text-zinc-400"
          >
          </p>
        </div>

        <div
          :if={Enum.any?(@category.actual_expenses)}
          id={"budget-category-actual-expenses-#{@category.id}"}
          class="budget-expense-fallback grid w-fit grid-cols-2 gap-x-1 gap-y-1 sm:grid-cols-4"
        >
          <.money_display
            :for={expense <- @category.actual_expenses}
            money={expense.price}
            display_currency={@display_currency}
            class="px-2 py-0.5 text-sm tabular-nums text-zinc-500 dark:text-zinc-400"
          />
        </div>
      </details>
    </div>
    """
  end

  @impl true
  def handle_event("expense_sheet_save", params, socket) do
    %{
      category: category,
      current_user: user,
      display_currency: display_currency
    } =
      socket.assigns

    result =
      if socket.assigns.can_edit do
        with {:ok, changes, opts} <- BudgetExpenseSheet.changes(params, display_currency) do
          Planning.save_actual_expense_cells(category, user, changes, opts)
        end
      else
        {:error, :unauthorized}
      end

    case result do
      {:ok, category} ->
        snapshot = BudgetExpenseSheet.snapshot(category, display_currency, true)
        {:reply, %{snapshot: snapshot}, assign(socket, :category, category)}

      {:error, {index, reason}} when is_integer(index) ->
        {:reply, %{index: index, error: BudgetExpenseSheet.error_message(reason)}, socket}

      {:error, reason} ->
        {:reply, %{error: BudgetExpenseSheet.error_message(reason)}, socket}
    end
  end

  def handle_event("edit", _params, socket) do
    if socket.assigns.can_edit do
      send(self(), {:open_form, "edit", "budget-category", socket.assigns.category.id})
      {:noreply, socket}
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end

  def handle_event("delete", _params, socket) do
    if socket.assigns.can_edit do
      case Planning.delete_budget_category(socket.assigns.category) do
        {:ok, _category} ->
          {:noreply, socket}

        {:error, :protected_category} ->
          {:noreply, put_flash(socket, :error, gettext("Food category cannot be deleted"))}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to delete category"))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end

  def handle_event("recalculate", _params, socket) do
    if socket.assigns.can_edit do
      case Planning.recalculate_budget_category_estimate(socket.assigns.category) do
        {:ok, _category} ->
          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to recalculate category"))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end

  defp category_label(%Category{} = category) do
    if Category.food?(category), do: gettext("Food"), else: category.name
  end
end
