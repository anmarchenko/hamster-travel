defmodule HamsterTravel.Planning.Notes do
  @moduledoc false

  import Ecto.Query, warn: false

  alias HamsterTravel.Planning.Note
  alias HamsterTravel.Planning.Policy
  alias HamsterTravel.Planning.PubSub
  alias HamsterTravel.Planning.Trip
  alias HamsterTravel.Planning.Common
  alias HamsterTravel.Repo

  def get_note!(id) do
    Repo.get!(Note, id)
  end

  def list_notes(%Trip{id: trip_id}) do
    list_notes(trip_id)
  end

  def list_notes(trip_id) do
    Repo.all(
      from n in Note,
        where: n.trip_id == ^trip_id,
        order_by: [asc_nulls_first: n.day_index, asc: n.rank]
    )
  end

  def create_note(trip, attrs \\ %{}) do
    %Note{trip_id: trip.id}
    |> Note.changeset(attrs)
    |> Repo.insert()
    |> PubSub.broadcast([:note, :created], trip.id)
  end

  def update_note(%Note{} = note, attrs) do
    note
    |> Note.changeset(attrs)
    |> Repo.update()
    |> PubSub.broadcast([:note, :updated], note.trip_id)
  end

  def new_note(trip, day_index \\ nil, attrs \\ %{}) do
    %Note{
      trip_id: trip.id,
      day_index: day_index
    }
    |> Note.changeset(attrs)
  end

  def change_note(%Note{} = note, attrs \\ %{}) do
    Note.changeset(note, attrs)
  end

  def delete_note(%Note{} = note) do
    Repo.delete(note)
    |> PubSub.broadcast([:note, :deleted], note.trip_id)
  end

  def notes_for_day(day_index, notes) do
    Common.singular_items_for_day(day_index, notes)
    |> Enum.sort_by(& &1.rank)
  end

  def notes_unassigned(notes) do
    notes
    |> Enum.filter(&is_nil(&1.day_index))
    |> Enum.sort_by(& &1.rank)
  end

  def move_note_to_day(note, new_day_index, trip, user, position \\ :last)

  def move_note_to_day(nil, _new_day_index, _trip, _user, _position),
    do: {:error, "Note not found"}

  def move_note_to_day(note, new_day_index, trip, user, position) do
    with :ok <- Policy.authorize_edit(trip, user),
         :ok <- validate_note_belongs_to_trip(note, trip),
         :ok <- validate_note_day_index_in_trip_duration(new_day_index, trip) do
      update_note_position(note, %{day_index: new_day_index, position: position})
    end
  end

  def reorder_note(nil, _position, _trip, _user), do: {:error, "Note not found"}

  def reorder_note(note, position, trip, user) do
    with :ok <- Policy.authorize_edit(trip, user),
         :ok <- validate_note_belongs_to_trip(note, trip) do
      update_note_position(note, %{position: position})
    end
  end

  def preloading_query do
    from n in Note, order_by: [asc_nulls_first: n.day_index, asc: n.rank]
  end

  defp validate_note_belongs_to_trip(note, %Trip{notes: notes}) do
    if Enum.any?(notes, &(&1.id == note.id)) do
      :ok
    else
      {:error, "Note not found"}
    end
  end

  defp validate_note_day_index_in_trip_duration(nil, _trip), do: :ok

  defp validate_note_day_index_in_trip_duration(day_index, %Trip{duration: duration}) do
    if day_index >= 0 and day_index < duration do
      :ok
    else
      {:error, "Day index must be between 0 and #{duration - 1}"}
    end
  end

  defp update_note_position(note, attrs) do
    note
    |> Note.changeset(attrs)
    |> Repo.update(stale_error_field: :id)
    |> PubSub.broadcast([:note, :updated], note.trip_id)
  end
end
