defmodule HamsterTravel.Planning.Common do
  @moduledoc false

  def items_for_day(day_index, items) do
    Enum.filter(items, fn item ->
      item.start_day <= day_index && item.end_day >= day_index
    end)
  end

  def singular_items_for_day(day_index, items) do
    Enum.filter(items, fn item ->
      item.day_index == day_index
    end)
  end

  def preload_after_db_call({:error, _} = res, _preload_fun), do: res

  def preload_after_db_call({:ok, record}, preload_fun) do
    record = preload_fun.(record)
    {:ok, record}
  end

  def validate_day_index_in_trip_duration(day_index, duration) do
    if day_index >= 0 and day_index < duration do
      :ok
    else
      {:error, "Day index must be between 0 and #{duration - 1}"}
    end
  end
end
