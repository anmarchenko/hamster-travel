defmodule HamsterTravelWeb.Planning.BudgetCategoryForm do
  @moduledoc """
  Budget category create/edit form.
  """

  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.BudgetCategory

  @impl true
  def update(assigns, socket) do
    category = Map.get(assigns, :category)
    estimation_mode = estimation_mode(category)
    changeset = category_changeset(assigns, %{})

    socket =
      socket
      |> assign(assigns)
      |> assign(:food, food_category?(category))
      |> assign(:estimation_mode, estimation_mode)
      |> assign_form(changeset)

    {:ok, socket}
  end

  attr :action, :atom, required: true
  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :category, BudgetCategory, default: nil
  attr :on_finish, :fun, required: true
  attr :can_edit, :boolean, default: false

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"budget-category-form-container-#{@id}"}>
      <.form
        id={"budget-category-form-#{@id}"}
        for={@form}
        as={:budget_category}
        phx-target={@myself}
        phx-change={@food && "form_changed"}
        phx-submit="form_submit"
        phx-mounted={JS.focus_first(to: "#budget-category-form-#{@id}")}
        class={[
          "py-2",
          @food && "max-w-3xl space-y-4",
          !@food && "max-w-3xl space-y-4"
        ]}
      >
        <div
          :if={!@food}
          class="grid grid-cols-1 gap-3 md:grid-cols-2 md:items-end"
        >
          <.field
            field={@form[:name]}
            type="text"
            label={gettext("Category name")}
            placeholder={gettext("e.g. Souvenirs")}
            wrapper_class="mb-0"
            required
          />

          <.inputs_for :let={expense_form} field={@form[:estimated_expense]}>
            <.money_input
              id={"budget-category-estimate-#{@id}"}
              field={expense_form[:price]}
              label={gettext("Estimated cost")}
              default_currency={@trip.currency}
            />
          </.inputs_for>
        </div>

        <div :if={!@food} class="flex justify-between">
          <.button color="light" type="button" phx-click="cancel" phx-target={@myself}>
            {gettext("Cancel")}
          </.button>
          <.button color="primary" size="xs" type="submit">
            {gettext("Save")}
          </.button>
        </div>

        <.field
          :if={@food}
          type="select"
          name="budget_category[estimation_mode]"
          id={"budget-category-estimation-mode-#{@id}"}
          value={@estimation_mode}
          label={gettext("Food estimate")}
          options={[
            {gettext("Total amount"), "total"},
            {gettext("Per day per person"), "per_day"}
          ]}
        />

        <.inputs_for
          :let={expense_form}
          :if={@food && @estimation_mode == "total"}
          field={@form[:estimated_expense]}
        >
          <.money_input
            id={"budget-category-estimate-#{@id}"}
            field={expense_form[:price]}
            label={gettext("Estimated cost")}
            default_currency={@trip.currency}
          />
        </.inputs_for>

        <.inputs_for
          :let={food_form}
          :if={@food}
          field={@form[:food_setting]}
        >
          <input
            type="hidden"
            name={food_form[:calculation_mode].name}
            value={@estimation_mode}
          />

          <div
            :if={@estimation_mode == "per_day"}
            class="grid grid-cols-1 items-start gap-4 sm:grid-cols-4"
          >
            <div class="sm:col-span-2">
              <.money_input
                id={"budget-category-price-per-day-#{@id}"}
                field={food_form[:price_per_day]}
                label={gettext("Price per day per person")}
                default_currency={@trip.currency}
              />
            </div>
            <.field
              field={food_form[:days_count]}
              type="number"
              min="1"
              step="1"
              label={gettext("Days")}
            />
            <.field
              field={food_form[:people_count]}
              type="number"
              min="1"
              step="1"
              label={gettext("People")}
            />
          </div>
        </.inputs_for>

        <div :if={@food} class="flex justify-between">
          <.button color="light" type="button" phx-click="cancel" phx-target={@myself}>
            {gettext("Cancel")}
          </.button>
          <.button color="primary" size="xs" type="submit">
            {gettext("Save")}
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def handle_event("form_changed", %{"budget_category" => params}, socket) do
    estimation_mode = estimation_mode(params)
    params = normalize_params(params, socket)
    changeset = category_changeset(socket.assigns, params)

    socket =
      socket
      |> assign(:estimation_mode, estimation_mode)
      |> assign_form(changeset)

    {:noreply, socket}
  end

  def handle_event("form_submit", %{"budget_category" => params}, socket) do
    if socket.assigns.can_edit do
      params = normalize_params(params, socket)
      submit(socket, socket.assigns.action, params)
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end

  def handle_event("cancel", _params, socket) do
    socket.assigns.on_finish.()
    {:noreply, socket}
  end

  defp submit(socket, :new, params) do
    socket.assigns.trip
    |> Planning.create_budget_category(params)
    |> result(socket)
  end

  defp submit(socket, :edit, params) do
    socket.assigns.category
    |> Planning.update_budget_category(params)
    |> result(socket)
  end

  defp result({:ok, _category}, socket) do
    socket.assigns.on_finish.()
    {:noreply, socket}
  end

  defp result({:error, changeset}, socket) do
    {:noreply, assign_form(socket, changeset)}
  end

  defp category_changeset(%{action: :new, trip: trip}, attrs) do
    Planning.new_budget_category(trip, normalize_params(attrs, trip))
  end

  defp category_changeset(%{action: :edit, category: category}, attrs) do
    Planning.change_budget_category(category, attrs)
  end

  defp normalize_params(params, %{assigns: assigns}) do
    normalize_params(params, assigns.trip, Map.get(assigns, :category))
  end

  defp normalize_params(params, trip), do: normalize_params(params, trip, nil)

  defp normalize_params(params, trip, category) do
    mode = estimation_mode(params)

    params
    |> Map.delete("kind")
    |> Map.delete("estimation_mode")
    |> normalize_estimate_fields(category, mode, trip)
  end

  defp normalize_estimate_fields(params, %BudgetCategory{} = category, mode, trip)
       when category.kind == "food" do
    params
    |> Map.put("name", "Food")
    |> put_food_setting_mode(mode, category, trip)
    |> maybe_remove_food_estimate(mode)
  end

  defp normalize_estimate_fields(params, _category, _mode, _trip) do
    Map.delete(params, "food_setting")
  end

  defp put_food_setting_mode(params, mode, category, trip) do
    defaults = %{
      "price_per_day" => category.food_setting.price_per_day,
      "days_count" => category.food_setting.days_count || trip.duration || 1,
      "people_count" => category.food_setting.people_count || trip.people_count || 1
    }

    food_setting =
      params
      |> Map.get("food_setting", %{})
      |> Map.merge(defaults, fn _key, submitted, _default -> submitted end)
      |> Map.put("calculation_mode", mode)

    Map.put(params, "food_setting", food_setting)
  end

  defp maybe_remove_food_estimate(params, "per_day"), do: Map.delete(params, "estimated_expense")
  defp maybe_remove_food_estimate(params, _mode), do: params

  defp estimation_mode(nil), do: "total"

  defp estimation_mode(%BudgetCategory{food_setting: %Ecto.Association.NotLoaded{}}), do: "total"
  defp estimation_mode(%BudgetCategory{food_setting: nil}), do: "total"

  defp estimation_mode(%BudgetCategory{food_setting: food_setting}),
    do: food_setting.calculation_mode

  defp estimation_mode(params) when is_map(params),
    do: Map.get(params, "estimation_mode", "total")

  defp food_category?(%BudgetCategory{} = category), do: BudgetCategory.food?(category)
  defp food_category?(_category), do: false

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
