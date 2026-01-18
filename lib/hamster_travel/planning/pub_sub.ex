defmodule HamsterTravel.Planning.PubSub do
  @moduledoc false

  @topic "planning"

  def broadcast({:ok, result} = return_tuple, event, trip_id) do
    Phoenix.PubSub.broadcast(
      HamsterTravel.PubSub,
      @topic <> ":#{trip_id}",
      {event, %{value: result}}
    )

    return_tuple
  end

  def broadcast({:error, _reason} = result, _, _), do: result
end
