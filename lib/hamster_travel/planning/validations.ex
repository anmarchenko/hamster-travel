defmodule HamsterTravel.Planning.Validations do
  @moduledoc """
  Shared validation functions for the Planning context.
  """

  import Ecto.Changeset

  @doc """
  Validates that end_day is greater than or equal to start_day.
  """
  def validate_end_day_after_start_day(changeset) do
    start_day = get_field(changeset, :start_day)
    end_day = get_field(changeset, :end_day)

    cond do
      is_nil(start_day) or is_nil(end_day) ->
        changeset

      end_day < start_day ->
        add_error(changeset, :end_day, "must be greater than or equal to start_day")

      true ->
        changeset
    end
  end
end
