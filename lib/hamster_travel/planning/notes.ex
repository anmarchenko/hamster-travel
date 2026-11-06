defmodule HamsterTravel.Planning.Notes do
  @moduledoc false

  import Ecto.Query, warn: false

  alias HamsterTravel.Planning.Note
  alias HamsterTravel.Planning.Policy
  alias HamsterTravel.Planning.PubSub
  alias HamsterTravel.Planning.Trip
  alias HamsterTravel.Repo

  def get_note!(id) do
    Repo.get!(Note, id)
  end

  def list_notes(%Trip{id: trip_id}) do
    list_notes(trip_id)
  end

  def list_notes(trip_id) do
    Repo.all(from n in preloading_query(), where: n.trip_id == ^trip_id)
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

  def new_note(trip, attrs \\ %{}) do
    %Note{trip_id: trip.id}
    |> Note.changeset(attrs)
  end

  def change_note(%Note{} = note, attrs \\ %{}) do
    Note.changeset(note, attrs)
  end

  def delete_note(%Note{} = note) do
    Repo.delete(note)
    |> PubSub.broadcast([:note, :deleted], note.trip_id)
  end

  def reorder_note(nil, _position, _trip, _user), do: {:error, "Note not found"}

  def reorder_note(note, position, trip, user) do
    with :ok <- Policy.authorize_edit(trip, user),
         :ok <- validate_note_belongs_to_trip(note, trip) do
      update_note_position(note, %{position: position})
    end
  end

  def preloading_query do
    from n in Note, order_by: [asc: n.rank, asc: n.id]
  end

  defp validate_note_belongs_to_trip(note, %Trip{notes: notes}) do
    if Enum.any?(notes, &(&1.id == note.id)) do
      :ok
    else
      {:error, "Note not found"}
    end
  end

  defp update_note_position(note, attrs) do
    note
    |> Note.changeset(attrs)
    |> Repo.update(stale_error_field: :id)
    |> PubSub.broadcast([:note, :updated], note.trip_id)
  end
end
