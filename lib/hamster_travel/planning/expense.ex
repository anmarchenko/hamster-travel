defmodule HamsterTravel.Planning.Expense do
  use Ecto.Schema
  import Ecto.Changeset

  @budget_role_estimate "category_estimate"
  @budget_role_actual "category_actual"
  @budget_roles [@budget_role_estimate, @budget_role_actual]

  schema "expenses" do
    field :price, Money.Ecto.Composite.Type
    field :name, :string
    field :budget_role, :string

    belongs_to(:trip, HamsterTravel.Planning.Trip, type: :binary_id)
    belongs_to(:accommodation, HamsterTravel.Planning.Accommodation)
    belongs_to(:transfer, HamsterTravel.Planning.Transfer)
    belongs_to(:activity, HamsterTravel.Planning.Activity)
    belongs_to(:day_expense, HamsterTravel.Planning.DayExpense)
    belongs_to(:food_expense, HamsterTravel.Planning.FoodExpense)
    belongs_to(:budget_category, HamsterTravel.Planning.BudgetCategory)

    timestamps()
  end

  @type t :: %__MODULE__{}

  def budget_role_estimate, do: @budget_role_estimate
  def budget_role_actual, do: @budget_role_actual

  def budget_role_actual?(%__MODULE__{budget_role: @budget_role_actual}), do: true
  def budget_role_actual?(_expense), do: false

  @doc false
  def changeset(expense, attrs) do
    expense
    |> cast(attrs, [
      :price,
      :name,
      :trip_id,
      :accommodation_id,
      :transfer_id,
      :activity_id,
      :day_expense_id,
      :food_expense_id,
      :budget_category_id,
      :budget_role
    ])
    |> validate_required([:price, :trip_id])
    |> validate_inclusion(:budget_role, @budget_roles)
  end
end
