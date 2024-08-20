defmodule HamsterTravel.Geo do
  @moduledoc """
  The Geo context.
  """

  import Ecto.Query, warn: false
  alias HamsterTravel.Repo

  alias HamsterTravel.Geo.{City, Country, Region}

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

  @doc """
  Gets a single region.

  Raises `Ecto.NoResultsError` if the Region does not exist.

  ## Examples

      iex> get_region!(123)
      %Region{}

      iex> get_region!(456)
      ** (Ecto.NoResultsError)

  """
  def get_region!(id), do: Repo.get!(Region, id)

  def find_region_by_geonames_id(geonames_id) do
    Repo.get_by(Region, geonames_id: geonames_id)
  end

  def find_region_by_code_and_country(region_code, country_code) do
    Repo.get_by(Region, country_code: country_code, region_code: region_code)
  end

  def find_city_by_geonames_id(geonames_id) do
    Repo.get_by(City, geonames_id: geonames_id)
  end

  def search_cities(search_term) do
    search_term = "#{search_term}%"

    query =
      from(
        c in City,
        where: ilike(c.name, ^search_term),
        order_by: [desc: fragment("? % ?", ^search_term, c.name), desc: c.population],
        limit: 50,
        preload: [:country],
        join: r in Region,
        on: c.region_code == r.region_code and c.country_code == r.country_code,
        select: %{c | region_name: r.name, region_name_ru: r.name_ru}
      )

    Repo.all(query)
  end

  @doc """
  Creates a region.

  ## Examples

      iex> create_region(%{field: value})
      {:ok, %Region{}}

      iex> create_region(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_region(attrs \\ %{}) do
    %Region{}
    |> Region.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a single city.

  Raises `Ecto.NoResultsError` if the City does not exist.

  ## Examples

      iex> get_city!(123)
      %City{}

      iex> get_city!(456)
      ** (Ecto.NoResultsError)

  """
  def get_city!(id), do: Repo.get!(City, id)

  @doc """
  Creates a city.

  ## Examples

      iex> create_city(%{field: value})
      {:ok, %City{}}

      iex> create_city(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_city(attrs \\ %{}) do
    %City{}
    |> City.changeset(attrs)
    |> Repo.insert()
  end
end
