defmodule HamsterTravel.Packing.Template do
  alias HamsterTravel.Packing.{Item, List}

  @doc """
  Parses YAML template from the provided file and converts it to the list of
  backpack lists.
  """
  def parse(nil, _), do: []

  def parse(template, vars \\ %{}) do
    filepath = "lib/hamster_travel/packing/templates/#{template}.yml"

    # TODO: validate yaml and return errors list
    case YamlElixir.read_from_file(filepath) do
      {:ok, %{backpack: lists}} ->
        lists
        |> Enum.map(fn list ->
          %List{
            name: list[:name],
            items:
              Enum.map(list[:items], fn item ->
                %Item{
                  name: item[:name],
                  count: item[:count]
                }
              end)
          }
        end)

      {:error, _} = error_tuple ->
        error_tuple

      _ ->
        {:error, "invalid template format"}
    end
  end
end
