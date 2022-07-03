defmodule HamsterTravel.Packing.Template do
  alias HamsterTravel.Packing.{Item, List}

  @doc """
  Parses YAML template from the provided file and converts it to the list of
  backpack lists.
  """
  def execute(template, vars \\ %{})
  def execute(nil, _), do: []

  def execute(template, vars) do
    filepath = "lib/hamster_travel/packing/templates/#{template}.yml"

    # TODO: validate yaml and return errors list
    case YamlElixir.read_from_file(filepath) do
      {:ok, %{"backpack" => lists}} ->
        lists
        |> Enum.map(fn list ->
          %List{
            name: list["name"],
            items:
              Enum.map(list["items"] || [], fn item ->
                %Item{
                  name: item["name"],
                  count: calculate_count(item["count"], vars)
                }
              end)
          }
        end)

      {:error, _} = error_tuple ->
        error_tuple

      re ->
        IO.puts(re)
        {:error, "invalid template format"}
    end
  end

  defp calculate_count(nil, _), do: 1
  defp calculate_count(count, _) when is_integer(count), do: count

  defp calculate_count(expression, vars) when is_binary(expression) do
    expression =
      Enum.reduce(
        vars,
        expression,
        fn {var, value}, expr ->
          String.replace(expr, Atom.to_string(var), Integer.to_string(value), global: true)
        end
      )

    {:ok, res} = Abacus.eval(expression)
    res
  end
end
