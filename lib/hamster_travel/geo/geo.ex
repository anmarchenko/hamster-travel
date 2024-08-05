defmodule HamsterTravel.Geo do
  @moduledoc """
  The Geo context.
  """

  import Ecto.Query, warn: false
  alias HamsterTravel.Repo

  alias HamsterTravel.Geo.Country

  @doc """
  Returns the list of countries.

  ## Examples

      iex> list_countries()
      [%Country{}, ...]

  """
  def list_countries do
    Repo.all(Country)
  end

  @doc """
  Returns the list of country ISO codes.
  """
  def list_country_iso_codes do
    Repo.all(from c in Country, select: c.iso, order_by: c.iso)
  end

  @doc """
  Gets a single country.

  Raises `Ecto.NoResultsError` if the Country does not exist.

  ## Examples

      iex> get_country!(123)
      %Country{}

      iex> get_country!(456)
      ** (Ecto.NoResultsError)

  """
  def get_country!(id), do: Repo.get!(Country, id)

  def find_country_by_geonames_id(geonames_id) do
    Repo.get_by(Country, geonames_id: geonames_id)
  end

  def find_country_by_iso(iso) do
    Repo.get_by(Country, iso: iso)
  end
end
