defmodule HamsterTravel.Planning.Accommodation do
  use Ecto.Schema
  import Ecto.Changeset

  alias HamsterTravel.Planning.Expense
  alias HamsterTravel.Planning.Validations
  alias Money

  schema "accommodations" do
    field :name, :string
    field :link, :string
    field :address, :string
    field :note, :string
    field :start_day, :integer
    field :end_day, :integer

    belongs_to(:trip, HamsterTravel.Planning.Trip, type: :binary_id)
    has_one(:expense, HamsterTravel.Planning.Expense)

    timestamps()
  end

  @doc false
  def changeset(accommodation, attrs) do
    accommodation
    |> cast(attrs, [:name, :link, :address, :note, :start_day, :end_day, :trip_id])
    |> cast_assoc(:expense, with: &Expense.changeset/2)
    |> validate_required([:name, :start_day, :end_day, :trip_id])
    |> validate_number(:start_day, greater_than_or_equal_to: 0)
    |> validate_number(:end_day, greater_than_or_equal_to: 0)
    |> Validations.validate_end_day_after_start_day()
  end

  @doc """
  Calculates the price per night for an accommodation.

  Returns the expense price divided by the number of nights.
  If there's no expense or the number of nights is 0, returns nil.

  ## Example

      iex> accommodation = %Accommodation{start_day: 1, end_day: 4, expense: %Expense{price: Money.new(300, :USD)}}
      iex> Accommodation.price_per_night(accommodation)
      %Money{amount: 100, currency: :USD}
  """
  def price_per_night(%__MODULE__{expense: nil}), do: nil

  def price_per_night(%__MODULE__{
        start_day: start_day,
        end_day: end_day,
        expense: %{price: price}
      }) do
    nights = end_day - start_day + 1

    case Money.div(price, nights) do
      {:ok, result} -> result
      {:error, _} -> nil
    end
  end

  def price_per_night(_), do: nil
end
