defmodule HamsterTravel.Planning.BudgetCategory do
  use Ecto.Schema
  import Ecto.Changeset

  alias HamsterTravel.Planning.BudgetCategoryFoodSetting
  alias HamsterTravel.Planning.Expense
  alias HamsterTravel.Planning.Trip

  @kind_general "general"
  @kind_food "food"
  @kinds [@kind_general, @kind_food]

  @estimate_role "category_estimate"
  @actual_role "category_actual"

  schema "budget_categories" do
    field :name, :string
    field :kind, :string, default: @kind_general

    belongs_to(:trip, Trip, type: :binary_id)

    has_one(:estimated_expense, Expense,
      foreign_key: :budget_category_id,
      where: [budget_role: @estimate_role]
    )

    has_many(:actual_expenses, Expense,
      foreign_key: :budget_category_id,
      where: [budget_role: @actual_role]
    )

    has_one(:food_setting, BudgetCategoryFoodSetting)

    timestamps()
  end

  @type t :: %__MODULE__{}

  def kind_general, do: @kind_general
  def kind_food, do: @kind_food
  def kinds, do: @kinds

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :kind, :trip_id])
    |> cast_assoc(:estimated_expense, with: &Expense.changeset/2)
    |> cast_assoc(:food_setting, with: &BudgetCategoryFoodSetting.changeset/2)
    |> validate_required([:name, :kind, :trip_id])
    |> validate_inclusion(:kind, @kinds)
    |> unique_constraint([:trip_id, :name])
  end
end
