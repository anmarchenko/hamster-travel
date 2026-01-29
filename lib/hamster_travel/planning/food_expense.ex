defmodule HamsterTravel.Planning.FoodExpense do
  use Ecto.Schema
  import Ecto.Changeset

  alias HamsterTravel.Planning.Expense
  alias HamsterTravel.Planning.Trip

  schema "food_expenses" do
    field :price_per_day, Money.Ecto.Composite.Type
    field :days_count, :integer
    field :people_count, :integer

    belongs_to(:trip, HamsterTravel.Planning.Trip, type: :binary_id)
    has_one(:expense, HamsterTravel.Planning.Expense)

    timestamps()
  end

  @doc false
  def changeset(food_expense, attrs) do
    food_expense
    |> cast(attrs, [:price_per_day, :days_count, :people_count, :trip_id])
    |> cast_assoc(:expense, with: &Expense.changeset/2)
    |> validate_required([:price_per_day, :days_count, :people_count, :trip_id])
    |> validate_number(:days_count, greater_than: 0)
    |> validate_number(:people_count, greater_than: 0)
    |> unique_constraint(:trip_id)
  end

  def build_food_expense_changeset(%__MODULE__{} = food_expense, %Trip{} = trip, attrs) do
    changeset = changeset(food_expense, attrs)
    total = food_expense_total(changeset, trip.currency)

    expense =
      case food_expense.expense do
        %Ecto.Association.NotLoaded{} -> %Expense{}
        nil -> %Expense{}
        %Expense{} = loaded -> loaded
      end

    expense_changeset =
      Expense.changeset(expense, %{
        price: total,
        trip_id: trip.id
      })

    Ecto.Changeset.put_assoc(changeset, :expense, expense_changeset)
  end

  def food_expense_total(changeset, currency) do
    price_per_day =
      changeset
      |> Ecto.Changeset.get_field(:price_per_day)
      |> normalize_money(currency)

    days_count =
      changeset
      |> Ecto.Changeset.get_field(:days_count)
      |> normalize_integer()

    people_count =
      changeset
      |> Ecto.Changeset.get_field(:people_count)
      |> normalize_integer()

    price_per_day
    |> Money.mult!(days_count)
    |> Money.mult!(people_count)
  end

  defp normalize_money(nil, currency), do: Money.new(currency, 0)
  defp normalize_money({:ok, %Money{} = money}, _currency), do: money
  defp normalize_money({:error, _}, currency), do: Money.new(currency, 0)
  defp normalize_money(%Money{} = money, _currency), do: money

  defp normalize_integer(nil), do: 0
  defp normalize_integer(value) when is_integer(value), do: value

  defp normalize_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> 0
    end
  end
end
