defmodule HamsterTravel.Planning.BudgetCategoryFoodSetting do
  use Ecto.Schema
  import Ecto.Changeset

  alias HamsterTravel.Planning.BudgetCategory

  @calculation_mode_total "total"
  @calculation_mode_per_day "per_day"
  @calculation_modes [@calculation_mode_total, @calculation_mode_per_day]

  schema "budget_category_food_settings" do
    field :price_per_day, Money.Ecto.Composite.Type
    field :days_count, :integer
    field :people_count, :integer
    field :calculation_mode, :string, default: @calculation_mode_per_day

    belongs_to(:budget_category, BudgetCategory)

    timestamps()
  end

  @type t :: %__MODULE__{}

  @doc false
  def changeset(food_setting, attrs) do
    food_setting
    |> cast(attrs, [
      :price_per_day,
      :days_count,
      :people_count,
      :calculation_mode,
      :budget_category_id
    ])
    |> validate_required([:price_per_day, :days_count, :people_count, :calculation_mode])
    |> validate_number(:days_count, greater_than: 0)
    |> validate_number(:people_count, greater_than: 0)
    |> validate_inclusion(:calculation_mode, @calculation_modes)
    |> unique_constraint(:budget_category_id)
  end

  def calculation_mode_total, do: @calculation_mode_total
  def calculation_mode_per_day, do: @calculation_mode_per_day

  def estimate_total(attrs, currency) do
    price_per_day =
      attrs
      |> get_attr(:price_per_day)
      |> normalize_money(currency)

    days_count =
      attrs
      |> get_attr(:days_count)
      |> normalize_integer()

    people_count =
      attrs
      |> get_attr(:people_count)
      |> normalize_integer()

    price_per_day
    |> Money.mult!(days_count)
    |> Money.mult!(people_count)
  end

  def price_per_day_from_total(total, days_count, people_count) do
    divisor = normalize_integer(days_count) * normalize_integer(people_count)

    if divisor > 0 do
      Money.div(total, divisor)
    else
      {:ok, Money.new(total.currency, 0)}
    end
  end

  defp get_attr(attrs, key) when is_map(attrs) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end

  defp get_attr(_attrs, _key), do: nil

  defp normalize_money(nil, currency), do: Money.new(currency, 0)
  defp normalize_money(%Money{} = money, _currency), do: money
  defp normalize_money({:ok, %Money{} = money}, _currency), do: money
  defp normalize_money({:error, _}, currency), do: Money.new(currency, 0)

  defp normalize_money(%{"amount" => amount, "currency" => currency}, _default_currency) do
    Money.new(currency, amount)
  end

  defp normalize_money(%{amount: amount, currency: currency}, _default_currency) do
    Money.new(currency, amount)
  end

  defp normalize_money(_value, currency), do: Money.new(currency, 0)

  defp normalize_integer(nil), do: 0
  defp normalize_integer(value) when is_integer(value), do: value

  defp normalize_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> 0
    end
  end

  defp normalize_integer(_value), do: 0
end
