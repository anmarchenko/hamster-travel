defmodule HamsterTravel.Planning do
  @moduledoc """
  The Planning context public API for trips, itineraries, and related records.

  Use these functions to manage trips and their associations.
  """

  alias HamsterTravel.Planning.{
    Accommodation,
    Accommodations,
    Activities,
    Activity,
    Common,
    DayExpense,
    DayExpenses,
    Destination,
    Destinations,
    Expense,
    Expenses,
    FoodExpense,
    FoodExpenses,
    Note,
    Notes,
    Transfer,
    Transfers,
    Trip,
    Trips
  }

  # Trip functions

  @doc """
  Lists planned and finished trips visible to a user.

  Pass `nil` to include only public trips or a `%User{}` to include private trips
  visible by the given user.
  Returns a list of `%Trip{}` structs with associations preloaded.

  ## Examples

      iex> list_plans(user)
      [%Trip{}, ...]
  """
  def list_plans(user \\ nil) do
    Trips.list_plans(user)
  end

  @doc """
  Lists draft trips visible to the given user.

  Pass the author `%User{}` to fetch their drafts.
  Returns a list of `%Trip{}` structs with associations preloaded.

  ## Examples

      iex> list_drafts(user)
      [%Trip{}, ...]
  """
  def list_drafts(user) do
    Trips.list_drafts(user)
  end

  @doc """
  Fetches a trip by id without raising.

  Pass the trip id as a binary.
  Returns `%Trip{}` with preloaded associations or `nil`.

  ## Examples

      iex> get_trip(trip.id)
      %Trip{}
  """
  def get_trip(id) do
    Trips.get_trip(id)
  end

  @doc """
  Fetches a trip by id and raises if it does not exist.

  Pass the trip id as a binary.
  Returns `%Trip{}` with preloaded associations or raises `Ecto.NoResultsError`.

  ## Examples

      iex> get_trip!(trip.id)
      %Trip{}
  """
  def get_trip!(id) do
    Trips.get_trip!(id)
  end

  @doc """
  Fetches a trip by slug with visibility rules.

  Pass the slug and the current user, or `nil` for public-only access.
  Returns `%Trip{}` with preloaded associations or raises `Ecto.NoResultsError`.

  ## Examples

      iex> fetch_trip!(trip.slug, user)
      %Trip{}
  """
  def fetch_trip!(slug, user) do
    Trips.fetch_trip!(slug, user)
  end

  @doc """
  Builds a changeset for validating a new trip.

  Pass a map of attributes; no defaults are applied.
  Returns `%Ecto.Changeset{}`.

  ## Examples

      iex> trip_changeset(%{"name" => "Rome"})
      %Ecto.Changeset{}
  """
  def trip_changeset(params) do
    Trips.trip_changeset(params)
  end

  @doc """
  Builds a changeset for a new trip with defaults merged in.

  Pass optional attributes to override defaults such as `currency` or `people_count`.
  Returns `%Ecto.Changeset{}`.

  ## Examples

      iex> new_trip(%{"name" => "Rome"})
      %Ecto.Changeset{}
  """
  def new_trip(params \\ %{}) do
    Trips.new_trip(params)
  end

  @doc """
  Creates a trip for the given author and initializes a default food expense.

  Pass a map of trip attributes and a `%User{}` author.
  Returns `{:ok, %Trip{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> create_trip(%{"name" => "Rome"}, user)
      {:ok, %Trip{}}
  """
  def create_trip(attrs \\ %{}, user) do
    Trips.create_trip(attrs, user)
  end

  @doc """
  Creates a trip by copying associations from another trip.

  Pass a map of trip attributes, a `%User{}` author, and a source `%Trip{}` to copy.
  Returns `{:ok, %Trip{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> create_trip(%{"name" => "Rome"}, user, trip)
      {:ok, %Trip{}}
  """
  def create_trip(attrs, user, %Trip{} = source_trip) do
    Trips.create_trip(attrs, user, source_trip)
  end

  @doc """
  Updates a trip and clamps destinations/accommodations when duration changes.

  Pass the existing `%Trip{}` and a map of changes.
  Returns `{:ok, %Trip{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> update_trip(trip, %{"name" => "New"})
      {:ok, %Trip{}}
  """
  def update_trip(%Trip{} = trip, attrs) do
    Trips.update_trip(trip, attrs)
  end

  @doc """
  Stores a trip cover and updates the trip with the stored file metadata.

  Returns `{:ok, %Trip{}}` or `{:error, reason}`.
  """
  def update_trip_cover(%Trip{} = trip, %Plug.Upload{} = upload) do
    Trips.update_trip_cover(trip, upload)
  end

  @doc """
  Creates a tombstone snapshot and hard-deletes the trip and its associations.

  Pass the `%Trip{}` to remove.
  Returns `{:ok, %Trip{}}` or `{:error, reason}`.

  ## Examples

      iex> delete_trip(trip)
      {:ok, %Trip{}}
  """
  def delete_trip(%Trip{} = trip) do
    Trips.delete_trip(trip)
  end

  @doc """
  Restores a trip and its associations from a tombstone.

  Pass a `%TripTombstone{}` or tombstone id.
  Returns `{:ok, %Trip{}}` or `{:error, reason}` and generates a unique slug if needed.

  ## Examples

      iex> restore_trip_from_tombstone(tombstone)
      {:ok, %Trip{}}
  """
  def restore_trip_from_tombstone(tombstone_or_id) do
    Trips.restore_trip_from_tombstone(tombstone_or_id)
  end

  @doc """
  Builds a changeset for editing an existing trip.

  Pass the `%Trip{}` and optional attribute changes.
  Returns `%Ecto.Changeset{}`.

  ## Examples

      iex> change_trip(trip, %{"name" => "New"})
      %Ecto.Changeset{}
  """
  def change_trip(%Trip{} = trip, attrs \\ %{}) do
    Trips.change_trip(trip, attrs)
  end

  # Destinations functions
  @doc """
  Fetches a destination by id and raises if missing.

  Pass the destination id.
  Returns `%Destination{}` with its city preloaded.

  ## Examples

      iex> get_destination!(destination.id)
      %Destination{}
  """
  def get_destination!(id) do
    Destinations.get_destination!(id)
  end

  @doc """
  Lists destinations for a trip.

  Pass a `%Trip{}` or trip id.
  Returns a list of `%Destination{}` structs with cities preloaded.

  ## Examples

      iex> list_destinations(trip)
      [%Destination{}, ...]
  """
  def list_destinations(trip_or_id) do
    Destinations.list_destinations(trip_or_id)
  end

  @doc """
  Creates a destination for a trip.

  Pass the `%Trip{}` and destination attributes.
  Returns `{:ok, %Destination{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> create_destination(trip, %{"city_id" => city.id})
      {:ok, %Destination{}}
  """
  def create_destination(trip, attrs \\ %{}) do
    Destinations.create_destination(trip, attrs)
  end

  @doc """
  Updates a destination.

  Pass the `%Destination{}` and attribute changes.
  Returns `{:ok, %Destination{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> update_destination(destination, %{"end_day" => 2})
      {:ok, %Destination{}}
  """
  def update_destination(%Destination{} = destination, attrs) do
    Destinations.update_destination(destination, attrs)
  end

  @doc """
  Builds a changeset for a new destination with default day bounds.

  Pass the trip, the day index to anchor, and optional attributes.
  Returns `%Ecto.Changeset{}`.

  ## Examples

      iex> new_destination(trip, 0)
      %Ecto.Changeset{}
  """
  def new_destination(trip, day_index, attrs \\ %{}) do
    Destinations.new_destination(trip, day_index, attrs)
  end

  @doc """
  Builds a changeset for editing a destination.

  Pass the `%Destination{}` and optional changes.
  Returns `%Ecto.Changeset{}`.

  ## Examples

      iex> change_destination(destination, %{"end_day" => 2})
      %Ecto.Changeset{}
  """
  def change_destination(%Destination{} = destination, attrs \\ %{}) do
    Destinations.change_destination(destination, attrs)
  end

  @doc """
  Deletes a destination.

  Pass the `%Destination{}` to remove.
  Returns `{:ok, %Destination{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> delete_destination(destination)
      {:ok, %Destination{}}
  """
  def delete_destination(%Destination{} = destination) do
    Destinations.delete_destination(destination)
  end

  @doc """
  Filters items that span the given day index.

  Pass the day index and a list of items with `start_day` and `end_day` fields.
  Returns the items whose range includes the given day.

  ## Examples

      iex> items_for_day(0, destinations)
      [%Destination{}, ...]
  """
  def items_for_day(day_index, items) do
    Common.items_for_day(day_index, items)
  end

  # Expense functions

  @doc """
  Fetches an expense by id and raises if missing.

  Pass the expense id.
  Returns `%Expense{}`.

  ## Examples

      iex> get_expense!(expense.id)
      %Expense{}
  """
  def get_expense!(id) do
    Expenses.get_expense!(id)
  end

  @doc """
  Lists expenses for a trip.

  Pass a `%Trip{}` or trip id.
  Returns a list of `%Expense{}` structs ordered by newest first.

  ## Examples

      iex> list_expenses(trip)
      [%Expense{}, ...]
  """
  def list_expenses(trip_or_id) do
    Expenses.list_expenses(trip_or_id)
  end

  @doc """
  Creates a standalone expense for a trip.

  Pass the `%Trip{}` and expense attributes.
  Returns `{:ok, %Expense{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> create_expense(trip, %{"name" => "Taxi"})
      {:ok, %Expense{}}
  """
  def create_expense(trip, attrs \\ %{}) do
    Expenses.create_expense(trip, attrs)
  end

  @doc """
  Updates an expense.

  Pass the `%Expense{}` and attribute changes.
  Returns `{:ok, %Expense{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> update_expense(expense, %{"name" => "Taxi"})
      {:ok, %Expense{}}
  """
  def update_expense(%Expense{} = expense, attrs) do
    Expenses.update_expense(expense, attrs)
  end

  @doc """
  Builds a changeset for a new expense.

  Pass the `%Trip{}` and optional attributes.
  Returns `%Ecto.Changeset{}`.

  ## Examples

      iex> new_expense(trip)
      %Ecto.Changeset{}
  """
  def new_expense(trip, attrs \\ %{}) do
    Expenses.new_expense(trip, attrs)
  end

  @doc """
  Builds a changeset for editing an expense.

  Pass the `%Expense{}` and optional changes.
  Returns `%Ecto.Changeset{}`.

  ## Examples

      iex> change_expense(expense, %{"name" => "Taxi"})
      %Ecto.Changeset{}
  """
  def change_expense(%Expense{} = expense, attrs \\ %{}) do
    Expenses.change_expense(expense, attrs)
  end

  @doc """
  Deletes an expense.

  Pass the `%Expense{}` to remove.
  Returns `{:ok, %Expense{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> delete_expense(expense)
      {:ok, %Expense{}}
  """
  def delete_expense(%Expense{} = expense) do
    Expenses.delete_expense(expense)
  end

  @doc """
  Calculates the total budget for a trip by summing all expenses.

  If expenses are not preloaded, they will be fetched from the database.
  Each expense is converted to the trip's currency before summing.
  Returns a Money struct in the trip's currency.

  ## Examples

      iex> trip = %Trip{currency: "EUR", expenses: [%Expense{price: Money.new(:EUR, 1000)}]}
      iex> calculate_budget(trip)
      %Money{amount: 1000, currency: :EUR}
  """
  def calculate_budget(%Trip{} = trip) do
    Expenses.calculate_budget(trip)
  end

  # Accommodation functions

  @doc """
  Fetches an accommodation by id and raises if missing.

  Pass the accommodation id.
  Returns `%Accommodation{}` with its expense preloaded.

  ## Examples

      iex> get_accommodation!(accommodation.id)
      %Accommodation{}
  """
  def get_accommodation!(id) do
    Accommodations.get_accommodation!(id)
  end

  @doc """
  Lists accommodations for a trip.

  Pass a `%Trip{}` or trip id.
  Returns a list of `%Accommodation{}` structs ordered by start day with expenses preloaded.

  ## Examples

      iex> list_accommodations(trip)
      [%Accommodation{}, ...]
  """
  def list_accommodations(trip_or_id) do
    Accommodations.list_accommodations(trip_or_id)
  end

  @doc """
  Creates an accommodation for a trip.

  Pass the `%Trip{}` and accommodation attributes, including nested expense attrs if present.
  Returns `{:ok, %Accommodation{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> create_accommodation(trip, %{"name" => "Hotel"})
      {:ok, %Accommodation{}}
  """
  def create_accommodation(trip, attrs \\ %{}) do
    Accommodations.create_accommodation(trip, attrs)
  end

  @doc """
  Updates an accommodation.

  Pass the `%Accommodation{}` and attribute changes.
  Returns `{:ok, %Accommodation{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> update_accommodation(accommodation, %{"name" => "Hotel"})
      {:ok, %Accommodation{}}
  """
  def update_accommodation(%Accommodation{} = accommodation, attrs) do
    Accommodations.update_accommodation(accommodation, attrs)
  end

  @doc """
  Builds a changeset for a new accommodation with default day bounds.

  Pass the trip, the day index to anchor, and optional attributes.
  Returns `%Ecto.Changeset{}`.

  ## Examples

      iex> new_accommodation(trip, 0)
      %Ecto.Changeset{}
  """
  def new_accommodation(trip, day_index, attrs \\ %{}) do
    Accommodations.new_accommodation(trip, day_index, attrs)
  end

  @doc """
  Builds a changeset for editing an accommodation.

  Pass the `%Accommodation{}` and optional changes.
  Returns `%Ecto.Changeset{}`.

  ## Examples

      iex> change_accommodation(accommodation, %{"name" => "Hotel"})
      %Ecto.Changeset{}
  """
  def change_accommodation(%Accommodation{} = accommodation, attrs \\ %{}) do
    Accommodations.change_accommodation(accommodation, attrs)
  end

  @doc """
  Deletes an accommodation.

  Pass the `%Accommodation{}` to remove.
  Returns `{:ok, %Accommodation{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> delete_accommodation(accommodation)
      {:ok, %Accommodation{}}
  """
  def delete_accommodation(%Accommodation{} = accommodation) do
    Accommodations.delete_accommodation(accommodation)
  end

  # Transfer functions

  @doc """
  Fetches a transfer by id and raises if missing.

  Pass the transfer id.
  Returns `%Transfer{}` with expense and cities preloaded.

  ## Examples

      iex> get_transfer!(transfer.id)
      %Transfer{}
  """
  def get_transfer!(id) do
    Transfers.get_transfer!(id)
  end

  @doc """
  Lists transfers for a trip.

  Pass a `%Trip{}` or trip id.
  Returns a list of `%Transfer{}` structs ordered by departure time with preloads.

  ## Examples

      iex> list_transfers(trip)
      [%Transfer{}, ...]
  """
  def list_transfers(trip_or_id) do
    Transfers.list_transfers(trip_or_id)
  end

  @doc """
  Creates a transfer for a trip.

  Pass the `%Trip{}` and transfer attributes, including nested expense attrs if present.
  Returns `{:ok, %Transfer{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> create_transfer(trip, %{"transport_mode" => "flight"})
      {:ok, %Transfer{}}
  """
  def create_transfer(trip, attrs \\ %{}) do
    Transfers.create_transfer(trip, attrs)
  end

  @doc """
  Updates a transfer.

  Pass the `%Transfer{}` and attribute changes.
  Returns `{:ok, %Transfer{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> update_transfer(transfer, %{"transport_mode" => "train"})
      {:ok, %Transfer{}}
  """
  def update_transfer(%Transfer{} = transfer, attrs) do
    Transfers.update_transfer(transfer, attrs)
  end

  @doc """
  Builds a changeset for a new transfer with defaults.

  Pass the trip, the day index, and optional attributes.
  Returns `%Ecto.Changeset{}`.

  ## Examples

      iex> new_transfer(trip, 0)
      %Ecto.Changeset{}
  """
  def new_transfer(trip, day_index, attrs \\ %{}) do
    Transfers.new_transfer(trip, day_index, attrs)
  end

  @doc """
  Builds a changeset for editing a transfer.

  Pass the `%Transfer{}` and optional changes.
  Returns `%Ecto.Changeset{}`.

  ## Examples

      iex> change_transfer(transfer, %{"note" => "Terminal 1"})
      %Ecto.Changeset{}
  """
  def change_transfer(%Transfer{} = transfer, attrs \\ %{}) do
    Transfers.change_transfer(transfer, attrs)
  end

  @doc """
  Deletes a transfer.

  Pass the `%Transfer{}` to remove.
  Returns `{:ok, %Transfer{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> delete_transfer(transfer)
      {:ok, %Transfer{}}
  """
  def delete_transfer(%Transfer{} = transfer) do
    Transfers.delete_transfer(transfer)
  end

  @doc """
  Moves a transfer to a new day after authorization and validation.

  Pass the `%Transfer{}`, new day index, trip, and current user.
  Returns `{:ok, %Transfer{}}` or `{:error, reason}`.

  ## Examples

      iex> move_transfer_to_day(transfer, 1, trip, user)
      {:ok, %Transfer{}}
  """
  def move_transfer_to_day(transfer, new_day_index, trip, user) do
    Transfers.move_transfer_to_day(transfer, new_day_index, trip, user)
  end

  @doc """
  Filters transfers for a day and sorts by departure time.

  Pass the day index and a list of transfers.
  Returns a list of `%Transfer{}`.

  ## Examples

      iex> transfers_for_day(0, transfers)
      [%Transfer{}, ...]
  """
  def transfers_for_day(day_index, transfers) do
    Transfers.transfers_for_day(day_index, transfers)
  end

  # Activity functions

  @doc """
  Fetches an activity by id and raises if missing.

  Pass the activity id.
  Returns `%Activity{}` with its expense preloaded.

  ## Examples

      iex> get_activity!(activity.id)
      %Activity{}
  """
  def get_activity!(id) do
    Activities.get_activity!(id)
  end

  @doc """
  Lists activities for a trip.

  Pass a `%Trip{}` or trip id.
  Returns a list of `%Activity{}` structs ordered by day and rank with expenses preloaded.

  ## Examples

      iex> list_activities(trip)
      [%Activity{}, ...]
  """
  def list_activities(trip_or_id) do
    Activities.list_activities(trip_or_id)
  end

  @doc """
  Creates an activity for a trip.

  Pass the `%Trip{}` and activity attributes, including nested expense attrs if present.
  Returns `{:ok, %Activity{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> create_activity(trip, %{"name" => "Museum"})
      {:ok, %Activity{}}
  """
  def create_activity(trip, attrs \\ %{}) do
    Activities.create_activity(trip, attrs)
  end

  @doc """
  Updates an activity.

  Pass the `%Activity{}` and attribute changes.
  Returns `{:ok, %Activity{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> update_activity(activity, %{"name" => "Museum"})
      {:ok, %Activity{}}
  """
  def update_activity(%Activity{} = activity, attrs) do
    Activities.update_activity(activity, attrs)
  end

  @doc """
  Builds a changeset for a new activity with defaults.

  Pass the trip, the day index, and optional attributes.
  Returns `%Ecto.Changeset{}`.

  ## Examples

      iex> new_activity(trip, 0)
      %Ecto.Changeset{}
  """
  def new_activity(trip, day_index, attrs \\ %{}) do
    Activities.new_activity(trip, day_index, attrs)
  end

  @doc """
  Builds a changeset for editing an activity.

  Pass the `%Activity{}` and optional changes.
  Returns `%Ecto.Changeset{}`.

  ## Examples

      iex> change_activity(activity, %{"name" => "Museum"})
      %Ecto.Changeset{}
  """
  def change_activity(%Activity{} = activity, attrs \\ %{}) do
    Activities.change_activity(activity, attrs)
  end

  @doc """
  Deletes an activity.

  Pass the `%Activity{}` to remove.
  Returns `{:ok, %Activity{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> delete_activity(activity)
      {:ok, %Activity{}}
  """
  def delete_activity(%Activity{} = activity) do
    Activities.delete_activity(activity)
  end

  @doc """
  Moves an activity to a new day after authorization and validation.

  Pass the `%Activity{}`, new day index, trip, user, and optional position.
  Returns `{:ok, %Activity{}}` or `{:error, reason}`.

  ## Examples

      iex> move_activity_to_day(activity, 1, trip, user)
      {:ok, %Activity{}}
  """
  def move_activity_to_day(activity, new_day_index, trip, user, position \\ :last) do
    Activities.move_activity_to_day(activity, new_day_index, trip, user, position)
  end

  @doc """
  Reorders an activity within its day after authorization and validation.

  Pass the `%Activity{}`, the new position, trip, and user.
  Returns `{:ok, %Activity{}}` or `{:error, reason}`.

  ## Examples

      iex> reorder_activity(activity, :first, trip, user)
      {:ok, %Activity{}}
  """
  def reorder_activity(activity, position, trip, user) do
    Activities.reorder_activity(activity, position, trip, user)
  end

  @doc """
  Filters activities for a day and sorts by rank.

  Pass the day index and a list of activities.
  Returns a list of `%Activity{}`.

  ## Examples

      iex> activities_for_day(0, activities)
      [%Activity{}, ...]
  """
  def activities_for_day(day_index, activities) do
    Activities.activities_for_day(day_index, activities)
  end

  # Notes functions

  @doc """
  Fetches a note by id and raises if missing.

  Pass the note id.
  Returns `%Note{}`.

  ## Examples

      iex> get_note!(note.id)
      %Note{}
  """
  def get_note!(id) do
    Notes.get_note!(id)
  end

  @doc """
  Lists notes for a trip.

  Pass a `%Trip{}` or trip id.
  Returns a list of `%Note{}` structs ordered by day index and rank.

  ## Examples

      iex> list_notes(trip)
      [%Note{}, ...]
  """
  def list_notes(trip_or_id) do
    Notes.list_notes(trip_or_id)
  end

  @doc """
  Creates a note for a trip.

  Pass the `%Trip{}` and note attributes.
  Returns `{:ok, %Note{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> create_note(trip, %{"title" => "Ideas"})
      {:ok, %Note{}}
  """
  def create_note(trip, attrs \\ %{}) do
    Notes.create_note(trip, attrs)
  end

  @doc """
  Updates a note.

  Pass the `%Note{}` and attribute changes.
  Returns `{:ok, %Note{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> update_note(note, %{"title" => "Ideas"})
      {:ok, %Note{}}
  """
  def update_note(%Note{} = note, attrs) do
    Notes.update_note(note, attrs)
  end

  @doc """
  Builds a changeset for a new note.

  Pass the trip, an optional day index, and optional attributes.
  Returns `%Ecto.Changeset{}`.

  ## Examples

      iex> new_note(trip, 0)
      %Ecto.Changeset{}
  """
  def new_note(trip, day_index \\ nil, attrs \\ %{}) do
    Notes.new_note(trip, day_index, attrs)
  end

  @doc """
  Builds a changeset for editing a note.

  Pass the `%Note{}` and optional changes.
  Returns `%Ecto.Changeset{}`.

  ## Examples

      iex> change_note(note, %{"title" => "Ideas"})
      %Ecto.Changeset{}
  """
  def change_note(%Note{} = note, attrs \\ %{}) do
    Notes.change_note(note, attrs)
  end

  @doc """
  Deletes a note.

  Pass the `%Note{}` to remove.
  Returns `{:ok, %Note{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> delete_note(note)
      {:ok, %Note{}}
  """
  def delete_note(%Note{} = note) do
    Notes.delete_note(note)
  end

  @doc """
  Filters notes for a day and sorts by rank.

  Pass the day index and a list of notes.
  Returns a list of `%Note{}`.

  ## Examples

      iex> notes_for_day(0, notes)
      [%Note{}, ...]
  """
  def notes_for_day(day_index, notes) do
    Notes.notes_for_day(day_index, notes)
  end

  @doc """
  Filters notes without a day assignment and sorts by rank.

  Pass a list of notes.
  Returns a list of `%Note{}` with `day_index` set to `nil`.

  ## Examples

      iex> notes_unassigned(notes)
      [%Note{}, ...]
  """
  def notes_unassigned(notes) do
    Notes.notes_unassigned(notes)
  end

  @doc """
  Moves a note to a new day after authorization and validation.

  Pass the `%Note{}`, new day index, trip, user, and optional position.
  Returns `{:ok, %Note{}}` or `{:error, reason}`.

  ## Examples

      iex> move_note_to_day(note, 1, trip, user)
      {:ok, %Note{}}
  """
  def move_note_to_day(note, new_day_index, trip, user, position \\ :last) do
    Notes.move_note_to_day(note, new_day_index, trip, user, position)
  end

  @doc """
  Reorders a note within its day after authorization and validation.

  Pass the `%Note{}`, the new position, trip, and user.
  Returns `{:ok, %Note{}}` or `{:error, reason}`.

  ## Examples

      iex> reorder_note(note, :first, trip, user)
      {:ok, %Note{}}
  """
  def reorder_note(note, position, trip, user) do
    Notes.reorder_note(note, position, trip, user)
  end

  # Day expense functions

  @doc """
  Fetches a day expense by id and raises if missing.

  Pass the day expense id.
  Returns `%DayExpense{}` with its expense preloaded.

  ## Examples

      iex> get_day_expense!(day_expense.id)
      %DayExpense{}
  """
  def get_day_expense!(id) do
    DayExpenses.get_day_expense!(id)
  end

  @doc """
  Lists day expenses for a trip.

  Pass a `%Trip{}` or trip id.
  Returns a list of `%DayExpense{}` structs ordered by day and rank with expenses preloaded.

  ## Examples

      iex> list_day_expenses(trip)
      [%DayExpense{}, ...]
  """
  def list_day_expenses(trip_or_id) do
    DayExpenses.list_day_expenses(trip_or_id)
  end

  @doc """
  Creates a day expense for a trip.

  Pass the `%Trip{}` and day expense attributes, including nested expense attrs if present.
  Returns `{:ok, %DayExpense{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> create_day_expense(trip, %{"name" => "Snacks"})
      {:ok, %DayExpense{}}
  """
  def create_day_expense(trip, attrs \\ %{}) do
    DayExpenses.create_day_expense(trip, attrs)
  end

  @doc """
  Updates a day expense.

  Pass the `%DayExpense{}` and attribute changes.
  Returns `{:ok, %DayExpense{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> update_day_expense(day_expense, %{"name" => "Snacks"})
      {:ok, %DayExpense{}}
  """
  def update_day_expense(%DayExpense{} = day_expense, attrs) do
    DayExpenses.update_day_expense(day_expense, attrs)
  end

  @doc """
  Builds a changeset for a new day expense with defaults.

  Pass the trip, the day index, and optional attributes.
  Returns `%Ecto.Changeset{}`.

  ## Examples

      iex> new_day_expense(trip, 0)
      %Ecto.Changeset{}
  """
  def new_day_expense(trip, day_index, attrs \\ %{}) do
    DayExpenses.new_day_expense(trip, day_index, attrs)
  end

  @doc """
  Builds a changeset for editing a day expense.

  Pass the `%DayExpense{}` and optional changes.
  Returns `%Ecto.Changeset{}`.

  ## Examples

      iex> change_day_expense(day_expense, %{"name" => "Snacks"})
      %Ecto.Changeset{}
  """
  def change_day_expense(%DayExpense{} = day_expense, attrs \\ %{}) do
    DayExpenses.change_day_expense(day_expense, attrs)
  end

  @doc """
  Deletes a day expense.

  Pass the `%DayExpense{}` to remove.
  Returns `{:ok, %DayExpense{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> delete_day_expense(day_expense)
      {:ok, %DayExpense{}}
  """
  def delete_day_expense(%DayExpense{} = day_expense) do
    DayExpenses.delete_day_expense(day_expense)
  end

  @doc """
  Moves a day expense to a new day after authorization and validation.

  Pass the `%DayExpense{}`, new day index, trip, user, and optional position.
  Returns `{:ok, %DayExpense{}}` or `{:error, reason}`.

  ## Examples

      iex> move_day_expense_to_day(day_expense, 1, trip, user)
      {:ok, %DayExpense{}}
  """
  def move_day_expense_to_day(day_expense, new_day_index, trip, user, position \\ :last) do
    DayExpenses.move_day_expense_to_day(day_expense, new_day_index, trip, user, position)
  end

  @doc """
  Reorders a day expense within its day after authorization and validation.

  Pass the `%DayExpense{}`, the new position, trip, and user.
  Returns `{:ok, %DayExpense{}}` or `{:error, reason}`.

  ## Examples

      iex> reorder_day_expense(day_expense, :first, trip, user)
      {:ok, %DayExpense{}}
  """
  def reorder_day_expense(day_expense, position, trip, user) do
    DayExpenses.reorder_day_expense(day_expense, position, trip, user)
  end

  @doc """
  Filters day expenses for a day and sorts by rank.

  Pass the day index and a list of day expenses.
  Returns a list of `%DayExpense{}`.

  ## Examples

      iex> day_expenses_for_day(0, day_expenses)
      [%DayExpense{}, ...]
  """
  def day_expenses_for_day(day_index, day_expenses) do
    DayExpenses.day_expenses_for_day(day_index, day_expenses)
  end

  # Food expense functions
  @doc """
  Fetches a food expense by id and raises if missing.

  Pass the food expense id.
  Returns `%FoodExpense{}` with its expense preloaded.

  ## Examples

      iex> get_food_expense!(food_expense.id)
      %FoodExpense{}
  """
  def get_food_expense!(id) do
    FoodExpenses.get_food_expense!(id)
  end

  @doc """
  Updates a food expense and its underlying expense record.

  Pass the `%FoodExpense{}` and attribute changes.
  Returns `{:ok, %FoodExpense{}}` or `{:error, %Ecto.Changeset{}}`.

  ## Examples

      iex> update_food_expense(food_expense, %{"people_count" => 2})
      {:ok, %FoodExpense{}}
  """
  def update_food_expense(%FoodExpense{} = food_expense, attrs) do
    FoodExpenses.update_food_expense(food_expense, attrs)
  end

  @doc """
  Builds a changeset for editing a food expense.

  Pass the `%FoodExpense{}` and optional changes.
  Returns `%Ecto.Changeset{}`.

  ## Examples

      iex> change_food_expense(food_expense, %{"people_count" => 2})
      %Ecto.Changeset{}
  """
  def change_food_expense(%FoodExpense{} = food_expense, attrs \\ %{}) do
    FoodExpenses.change_food_expense(food_expense, attrs)
  end
end
