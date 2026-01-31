defmodule HamsterTravel.Planning.Transfers do
  @moduledoc false

  import Ecto.Query, warn: false

  alias HamsterTravel.Geo
  alias HamsterTravel.Planning.Common
  alias HamsterTravel.Planning.Expense
  alias HamsterTravel.Planning.Policy
  alias HamsterTravel.Planning.PubSub
  alias HamsterTravel.Planning.Transfer
  alias HamsterTravel.Planning.Trip
  alias HamsterTravel.Repo

  def get_transfer!(id) do
    Repo.get!(Transfer, id)
    |> preloading()
  end

  def list_transfers(%Trip{id: trip_id}) do
    list_transfers(trip_id)
  end

  def list_transfers(trip_id) do
    Repo.all(from t in Transfer, where: t.trip_id == ^trip_id, order_by: [asc: t.departure_time])
    |> preloading()
  end

  def create_transfer(trip, attrs \\ %{}) do
    # Ensure the expense has trip_id if it exists in attrs
    attrs =
      case Map.get(attrs, "expense") do
        nil -> attrs
        expense_attrs -> Map.put(attrs, "expense", Map.put(expense_attrs, "trip_id", trip.id))
      end

    %Transfer{trip_id: trip.id}
    |> Transfer.changeset(attrs)
    |> Repo.insert()
    |> Common.preload_after_db_call(&preloading(&1))
    |> PubSub.broadcast([:transfer, :created], trip.id)
  end

  def update_transfer(%Transfer{} = transfer, attrs) do
    transfer
    |> Transfer.changeset(attrs)
    |> Repo.update()
    |> Common.preload_after_db_call(&preloading(&1))
    |> PubSub.broadcast([:transfer, :updated], transfer.trip_id)
  end

  def new_transfer(trip, day_index, attrs \\ %{}) do
    %Transfer{
      transport_mode: "flight",
      trip_id: trip.id,
      departure_city: nil,
      arrival_city: nil,
      day_index: day_index,
      expense: %Expense{price: Money.new(trip.currency, 0)}
    }
    |> Transfer.changeset(attrs)
  end

  def change_transfer(%Transfer{} = transfer, attrs \\ %{}) do
    Transfer.changeset(transfer, attrs)
  end

  def delete_transfer(%Transfer{} = transfer) do
    Repo.delete(transfer)
    |> PubSub.broadcast([:transfer, :deleted], transfer.trip_id)
  end

  def move_transfer_to_day(nil, _new_day_index, _trip, _user), do: {:error, "Transfer not found"}

  def move_transfer_to_day(transfer, new_day_index, trip, user) do
    with :ok <- Policy.authorize_edit(trip, user),
         :ok <- validate_transfer_belongs_to_trip(transfer, trip),
         :ok <- Common.validate_day_index_in_trip_duration(new_day_index, trip.duration) do
      update_transfer_day_index(transfer, new_day_index)
    end
  end

  def transfers_for_day(day_index, transfers) do
    Common.singular_items_for_day(day_index, transfers)
    |> Enum.sort_by(& &1.departure_time)
  end

  def preloading_query do
    [
      :expense,
      departure_city: Geo.city_preloading_query(),
      arrival_city: Geo.city_preloading_query()
    ]
  end

  defp validate_transfer_belongs_to_trip(transfer, %Trip{transfers: transfers}) do
    if Enum.any?(transfers, &(&1.id == transfer.id)) do
      :ok
    else
      {:error, "Transfer not found"}
    end
  end

  defp update_transfer_day_index(transfer, new_day_index) do
    transfer
    |> Transfer.changeset(%{day_index: new_day_index})
    |> Repo.update(stale_error_field: :id)
    |> Common.preload_after_db_call(&preloading(&1))
    |> PubSub.broadcast([:transfer, :updated], transfer.trip_id)
  end

  defp preloading(query) do
    query
    |> Repo.preload(preloading_query())
  end
end
