defmodule HamsterTravel.Planning.BudgetCategories do
  @moduledoc false

  import Ecto.Query, warn: false

  alias HamsterTravel.Planning.BudgetCategory
  alias HamsterTravel.Planning.BudgetCategoryFoodSetting
  alias HamsterTravel.Planning.Common
  alias HamsterTravel.Planning.Expense
  alias HamsterTravel.Planning.PubSub
  alias HamsterTravel.Planning.Trip
  alias HamsterTravel.Repo

  def get_budget_category!(id) do
    Repo.get!(BudgetCategory, id)
    |> preloading()
  end

  def list_budget_categories(%Trip{id: trip_id}), do: list_budget_categories(trip_id)

  def list_budget_categories(trip_id) do
    Repo.all(
      from category in BudgetCategory,
        where: category.trip_id == ^trip_id,
        order_by: [asc: category.name]
    )
    |> preloading()
  end

  def create_budget_category(%Trip{} = trip, attrs \\ %{}) do
    attrs = normalize_category_attrs(trip, attrs)

    %BudgetCategory{trip_id: trip.id}
    |> BudgetCategory.changeset(attrs)
    |> Repo.insert()
    |> Common.preload_after_db_call(&preloading(&1))
    |> PubSub.broadcast([:budget_category, :created], trip.id)
  end

  def update_budget_category(%BudgetCategory{} = category, attrs) do
    category =
      category
      |> Repo.preload([:trip | preloading_query()])

    attrs = normalize_category_attrs(category.trip, attrs, category)

    category
    |> BudgetCategory.changeset(attrs)
    |> Repo.update()
    |> Common.preload_after_db_call(&preloading(&1))
    |> PubSub.broadcast([:budget_category, :updated], category.trip_id)
  end

  def change_budget_category(%BudgetCategory{} = category, attrs \\ %{}) do
    BudgetCategory.changeset(category, attrs)
  end

  def delete_budget_category(%BudgetCategory{} = category) do
    Repo.delete(category)
    |> PubSub.broadcast([:budget_category, :deleted], category.trip_id)
  end

  def create_budget_category_actual_expense(%BudgetCategory{} = category, attrs \\ %{}) do
    category = Repo.preload(category, [:trip])

    Repo.transaction(fn ->
      attrs = normalize_actual_expense_attrs(category, attrs)

      %Expense{
        trip_id: category.trip_id,
        budget_category_id: category.id,
        budget_role: Expense.budget_role_actual()
      }
      |> Expense.changeset(attrs)
      |> Repo.insert()
      |> case do
        {:ok, expense} ->
          case raise_estimate_if_actual_sum_exceeds(category) do
            :ok -> expense
            {:error, changeset} -> Repo.rollback(changeset)
          end

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
    |> broadcast_expense_event([:budget_category_actual_expense, :created], category.trip_id)
  end

  def update_budget_category_actual_expense(%Expense{} = expense, attrs) do
    with :ok <- validate_actual_expense(expense),
         %BudgetCategory{} = category <- get_actual_expense_category(expense) do
      Repo.transaction(fn ->
        expense
        |> Expense.changeset(attrs)
        |> Repo.update()
        |> case do
          {:ok, updated_expense} ->
            case raise_estimate_if_actual_sum_exceeds(category) do
              :ok -> updated_expense
              {:error, changeset} -> Repo.rollback(changeset)
            end

          {:error, changeset} ->
            Repo.rollback(changeset)
        end
      end)
      |> broadcast_expense_event([:budget_category_actual_expense, :updated], expense.trip_id)
    end
  end

  def delete_budget_category_actual_expense(%Expense{} = expense) do
    with :ok <- validate_actual_expense(expense) do
      Repo.delete(expense)
      |> PubSub.broadcast([:budget_category_actual_expense, :deleted], expense.trip_id)
    end
  end

  def recalculate_budget_category_estimate(%BudgetCategory{} = category) do
    category = preloading(category)
    total = actual_expenses_sum(category, category.trip.currency)

    set_estimate_price(category, total)
    |> PubSub.broadcast([:budget_category, :updated], category.trip_id)
  end

  def maybe_recalculate_after_trip_finished(%Trip{} = updated_trip, %Trip{} = original_trip) do
    if updated_trip.status == Trip.finished() and original_trip.status != Trip.finished() do
      case recalculate_trip_category_estimates(updated_trip, skip_zero_actuals: true) do
        :ok -> {:ok, updated_trip}
        {:error, changeset} -> {:error, changeset}
      end
    else
      {:ok, updated_trip}
    end
  end

  def recalculate_trip_category_estimates(%Trip{} = trip, opts \\ []) do
    skip_zero_actuals? = Keyword.get(opts, :skip_zero_actuals, false)

    trip
    |> list_budget_categories()
    |> Enum.reduce_while(:ok, fn category, :ok ->
      total = actual_expenses_sum(category, trip.currency)

      if skip_zero_actuals? and zero_money?(total) do
        {:cont, :ok}
      else
        case set_estimate_price(category, total) do
          {:ok, _category} -> {:cont, :ok}
          {:error, changeset} -> {:halt, {:error, changeset}}
        end
      end
    end)
  end

  def preloading_query do
    [:trip, :estimated_expense, :actual_expenses, :food_setting]
  end

  defp normalize_category_attrs(%Trip{} = trip, attrs, category \\ nil) do
    attrs = stringify_keys(attrs)
    category_name = Map.get(attrs, "name") || category_name(category)
    kind = Map.get(attrs, "kind") || category_kind(category) || BudgetCategory.kind_general()
    food_setting_attrs = Map.get(attrs, "food_setting")

    attrs
    |> Map.put("trip_id", trip.id)
    |> Map.put("kind", kind)
    |> put_existing_food_setting_id(category)
    |> put_default_estimated_expense_attrs(
      trip,
      category,
      category_name,
      kind,
      food_setting_attrs
    )
  end

  defp put_default_estimated_expense_attrs(
         attrs,
         trip,
         category,
         category_name,
         kind,
         food_setting_attrs
       ) do
    cond do
      Map.has_key?(attrs, "estimated_expense") ->
        Map.update!(attrs, "estimated_expense", fn expense_attrs ->
          trip
          |> normalize_estimated_expense_attrs(category_name, expense_attrs)
          |> put_existing_estimated_expense_id(category)
        end)

      kind == BudgetCategory.kind_food() and is_map(food_setting_attrs) ->
        estimated_expense_attrs =
          trip
          |> default_estimated_expense_attrs(category_name, kind, food_setting_attrs)
          |> put_existing_estimated_expense_id(category)

        Map.put(attrs, "estimated_expense", estimated_expense_attrs)

      existing_estimated_expense?(category) ->
        attrs

      true ->
        estimated_expense_attrs =
          default_estimated_expense_attrs(trip, category_name, kind, food_setting_attrs)

        Map.put(attrs, "estimated_expense", estimated_expense_attrs)
    end
  end

  defp put_existing_food_setting_id(attrs, %BudgetCategory{
         food_setting: %BudgetCategoryFoodSetting{id: food_setting_id}
       }) do
    update_nested_id(attrs, "food_setting", food_setting_id)
  end

  defp put_existing_food_setting_id(attrs, _category), do: attrs

  defp put_existing_estimated_expense_id(attrs, %BudgetCategory{
         estimated_expense: %Expense{id: expense_id}
       }) do
    Map.put_new(attrs, "id", expense_id)
  end

  defp put_existing_estimated_expense_id(attrs, _category), do: attrs

  defp existing_estimated_expense?(%BudgetCategory{estimated_expense: %Expense{}}), do: true
  defp existing_estimated_expense?(_category), do: false

  defp update_nested_id(attrs, key, id) do
    if Map.has_key?(attrs, key) do
      Map.update!(attrs, key, fn nested_attrs ->
        nested_attrs
        |> stringify_keys()
        |> Map.put_new("id", id)
      end)
    else
      attrs
    end
  end

  defp default_estimated_expense_attrs(trip, category_name, kind, food_setting_attrs) do
    price =
      if kind == BudgetCategory.kind_food() and is_map(food_setting_attrs) do
        BudgetCategoryFoodSetting.estimate_total(food_setting_attrs, trip.currency)
      else
        Money.new(trip.currency, 0)
      end

    normalize_estimated_expense_attrs(trip, category_name, %{price: price})
  end

  defp normalize_estimated_expense_attrs(trip, category_name, expense_attrs) do
    expense_attrs
    |> stringify_keys()
    |> Map.put("trip_id", trip.id)
    |> Map.put("budget_role", Expense.budget_role_estimate())
    |> Map.put_new("name", category_name)
  end

  defp normalize_actual_expense_attrs(%BudgetCategory{} = category, attrs) do
    attrs
    |> stringify_keys()
    |> Map.put("trip_id", category.trip_id)
    |> Map.put("budget_category_id", category.id)
    |> Map.put("budget_role", Expense.budget_role_actual())
    |> Map.put_new("name", category.name)
  end

  defp raise_estimate_if_actual_sum_exceeds(%BudgetCategory{} = category) do
    category = preloading(category)
    total = actual_expenses_sum(category, category.trip.currency)
    estimate = estimate_price(category, category.trip.currency)

    if money_gt?(total, estimate, category.trip.currency) do
      case set_estimate_price(category, total) do
        {:ok, _category} -> :ok
        {:error, changeset} -> {:error, changeset}
      end
    else
      :ok
    end
  end

  defp set_estimate_price(%BudgetCategory{} = category, %Money{} = price) do
    category = preloading(category)
    estimate = category.estimated_expense || new_estimate_expense(category)

    estimate
    |> Expense.changeset(%{
      name: category.name,
      price: price,
      trip_id: category.trip_id,
      budget_category_id: category.id,
      budget_role: Expense.budget_role_estimate()
    })
    |> Repo.insert_or_update()
    |> case do
      {:ok, _expense} -> maybe_update_food_setting(category, price)
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp maybe_update_food_setting(
         %BudgetCategory{kind: kind, food_setting: %BudgetCategoryFoodSetting{} = food_setting},
         price
       )
       when kind == "food" do
    with {:ok, price_per_day} <-
           BudgetCategoryFoodSetting.price_per_day_from_total(
             price,
             food_setting.days_count,
             food_setting.people_count
           ),
         {:ok, _food_setting} <-
           food_setting
           |> BudgetCategoryFoodSetting.changeset(%{price_per_day: price_per_day})
           |> Repo.update() do
      {:ok, get_budget_category!(food_setting.budget_category_id)}
    end
  end

  defp maybe_update_food_setting(%BudgetCategory{} = category, _price) do
    {:ok, get_budget_category!(category.id)}
  end

  defp new_estimate_expense(%BudgetCategory{} = category) do
    %Expense{
      trip_id: category.trip_id,
      budget_category_id: category.id,
      budget_role: Expense.budget_role_estimate()
    }
  end

  defp actual_expenses_sum(%BudgetCategory{} = category, currency) do
    category.id
    |> actual_expenses_query()
    |> Repo.all()
    |> Enum.map(&convert_expense_to_currency(&1, currency))
    |> sum_money(currency)
  end

  defp actual_expenses_query(category_id) do
    from expense in Expense,
      where:
        expense.budget_category_id == ^category_id and
          expense.budget_role == ^Expense.budget_role_actual()
  end

  defp estimate_price(%BudgetCategory{estimated_expense: %Expense{price: price}}, currency) do
    convert_money_to_currency(price, currency)
  end

  defp estimate_price(%BudgetCategory{}, currency), do: Money.new(currency, 0)

  defp convert_expense_to_currency(%Expense{price: price}, currency),
    do: convert_money_to_currency(price, currency)

  defp convert_money_to_currency(%Money{currency: currency} = money, currency), do: money

  defp convert_money_to_currency(%Money{} = money, currency) do
    case Money.to_currency(money, currency) do
      {:ok, converted_money} -> converted_money
      {:error, _reason} -> Money.new(currency, 0)
    end
  end

  defp sum_money(moneys, currency) do
    Enum.reduce(moneys, Money.new(currency, 0), fn money, acc ->
      case Money.add(acc, money) do
        {:ok, sum} -> sum
        {:error, _reason} -> acc
      end
    end)
  end

  defp money_gt?(left, right, currency) do
    left = convert_money_to_currency(left, currency)
    right = convert_money_to_currency(right, currency)

    Decimal.compare(left.amount, right.amount) == :gt
  end

  defp zero_money?(%Money{} = money), do: Money.equal?(money, Money.new(money.currency, 0))

  defp validate_actual_expense(%Expense{} = expense) do
    if Expense.budget_role_actual?(expense) and not is_nil(expense.budget_category_id) do
      :ok
    else
      {:error, :not_budget_category_actual_expense}
    end
  end

  defp get_actual_expense_category(%Expense{} = expense) do
    BudgetCategory
    |> Repo.get!(expense.budget_category_id)
    |> Repo.preload([:trip])
  end

  defp category_name(%BudgetCategory{name: name}), do: name
  defp category_name(_category), do: nil

  defp category_kind(%BudgetCategory{kind: kind}), do: kind
  defp category_kind(_category), do: nil

  defp stringify_keys(attrs) when is_map(attrs) do
    Map.new(attrs, fn {key, value} -> {to_string(key), value} end)
  end

  defp stringify_keys(_attrs), do: %{}

  defp preloading(records) when is_list(records), do: Repo.preload(records, preloading_query())
  defp preloading(record), do: Repo.preload(record, preloading_query())

  defp broadcast_expense_event({:ok, _expense} = result, event, trip_id) do
    PubSub.broadcast(result, event, trip_id)
  end

  defp broadcast_expense_event({:error, _reason} = result, _event, _trip_id), do: result
end
