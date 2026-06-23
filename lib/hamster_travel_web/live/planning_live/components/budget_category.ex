defmodule HamsterTravelWeb.Planning.BudgetCategory do
  @moduledoc """
  Displays a budget category, its estimate, and its actual expenses.
  """

  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.BudgetCategory, as: Category
  alias HamsterTravel.Planning.Trip

  @impl true
  def mount(socket) do
    {:ok, assign(socket, edit: false, add_actual: false, actual_form_version: 0)}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_actual_form()

    {:ok, socket}
  end

  attr :category, Category, required: true
  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :display_currency, :string, required: true
  attr :can_edit, :boolean, default: false

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
        can_edit={@can_edit}
        on_finish={fn -> send_update(@myself, edit: false) end}
      />
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div id={"budget-category-#{@category.id}"} class="max-w-3xl py-1">
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

      <div
        :if={@can_edit || Enum.any?(@category.actual_expenses)}
        class="ml-4 max-w-3xl border-l border-zinc-200 py-1 pl-4 dark:border-zinc-700"
      >
        <div
          :if={Enum.any?(@category.actual_expenses)}
          id={"budget-category-actual-expenses-#{@category.id}"}
          class="grid grid-cols-2 gap-x-3 gap-y-1 sm:grid-cols-3 lg:grid-cols-4"
        >
          <.live_component
            :for={expense <- @category.actual_expenses}
            module={HamsterTravelWeb.Planning.BudgetCategoryActualExpense}
            id={"budget-category-actual-#{expense.id}"}
            expense={expense}
            trip={@trip}
            display_currency={@display_currency}
            can_edit={@can_edit}
          />
        </div>

        <.form
          :if={@add_actual}
          id={"budget-category-actual-new-form-#{@category.id}-#{@actual_form_version}"}
          for={@actual_form}
          as={:expense}
          phx-target={@myself}
          phx-submit="save_actual"
          phx-window-keydown="cancel_actual"
          phx-key="escape"
          phx-mounted={
            JS.focus_first(
              to: "#budget-category-actual-new-form-#{@category.id}-#{@actual_form_version}"
            )
          }
          class="mt-2 flex max-w-2xl flex-col gap-3 sm:flex-row sm:items-start"
        >
          <div class="grow">
            <.money_input
              id={"budget-category-actual-new-price-#{@category.id}"}
              field={@actual_form[:price]}
              label={
                gettext("Actual expense for %{category}",
                  category: category_label(@category)
                )
              }
              default_currency={@trip.currency}
              reserve_error_space
            />
          </div>
          <div class="flex gap-2 sm:mt-7">
            <.button color="light" type="button" phx-click="cancel_actual" phx-target={@myself}>
              {gettext("Cancel")}
            </.button>
            <.button color="primary" size="xs" type="submit">
              {gettext("Save")}
            </.button>
          </div>
        </.form>

        <button
          :if={!@add_actual}
          type="button"
          phx-click="add_actual"
          phx-target={@myself}
          class="mt-1 inline-flex items-center gap-1.5 py-0.5 text-sm font-normal text-zinc-400 transition-colors hover:text-primary-600 focus-visible:text-primary-600 focus-visible:outline-none dark:text-zinc-500 dark:hover:text-primary-300"
        >
          <.icon name="hero-plus-solid" class="h-4 w-4" />
          <span>
            {gettext("Add actual expense for %{category}",
              category: category_label(@category)
            )}
          </span>
        </button>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("add_actual", _params, socket) do
    if socket.assigns.can_edit do
      {:noreply, assign(socket, :add_actual, true)}
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end

  def handle_event("cancel_actual", _params, socket) do
    {:noreply, assign(socket, :add_actual, false)}
  end

  def handle_event("save_actual", %{"expense" => params}, socket) do
    if socket.assigns.can_edit do
      socket.assigns.category
      |> Planning.create_budget_category_actual_expense(params)
      |> actual_result(socket)
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end

  def handle_event("edit", _params, socket) do
    if socket.assigns.can_edit do
      {:noreply, assign(socket, :edit, true)}
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

  defp actual_result({:ok, _expense}, socket) do
    {:noreply,
     socket
     |> assign(:add_actual, true)
     |> update(:actual_form_version, &(&1 + 1))
     |> assign_actual_form()}
  end

  defp actual_result({:error, changeset}, socket) do
    {:noreply, assign(socket, :actual_form, to_form(changeset))}
  end

  defp assign_actual_form(socket) do
    expense =
      Planning.new_expense(socket.assigns.trip, %{
        name: socket.assigns.category.name,
        price: Money.new(socket.assigns.trip.currency, 0)
      })

    assign(socket, :actual_form, to_form(expense))
  end

  defp category_label(%Category{} = category) do
    if Category.food?(category), do: gettext("Food"), else: category.name
  end
end
