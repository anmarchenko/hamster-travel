defmodule HamsterTravel.Packing.Template do
  alias HamsterTravel.Packing.{Item, List}
  alias HamsterTravel.Result

  @doc """
  Parses YAML template from the provided file and converts it to the list of
  backpack lists.
  """
  def execute(template, vars \\ %{})
  def execute(nil, _), do: []

  @spec execute(String.t(), Map.t()) :: {:ok, list(List.t())} | {:error, list(String.t())}
  def execute(template, vars) do
    filepath = "lib/hamster_travel/packing/templates/#{template}.yml"

    with {:ok, %{"backpack" => lists}} <- YamlElixir.read_from_file(filepath) do
      lists
      |> Enum.map(fn list -> parse_list(list, vars) end)
      |> Result.list_or_errors()
    else
      {:error, %{message: message}} ->
        {:error, [message]}

      {:error, error} when is_binary(error) ->
        {:error, [error]}

      _ ->
        {:error, ["invalid template format"]}
    end
  end

  defp parse_list(nil, _), do: %List{}

  defp parse_list(list_map, vars) do
    with {:ok, items} <- parse_items(list_map["items"], vars) do
      %List{
        name: list_map["name"],
        items: items
      }
    else
      {:error, _} = error_tuple ->
        error_tuple
    end
  end

  defp parse_items(nil, _), do: {:ok, []}
  defp parse_items([], _), do: {:ok, []}

  defp parse_items(items, vars) when is_list(items) do
    items
    |> Enum.map(fn item -> parse_item(item, vars) end)
    |> Result.list_or_errors()
  end

  defp parse_item(nil, _), do: %Item{}

  defp parse_item(item, vars) do
    with {:ok, num} <- calculate_count(item["count"], vars) do
      %Item{
        name: item["name"],
        count: num
      }
    else
      {:error, %{description: description}} ->
        {:error, [description]}

      {:error, {_, :new_parser, errors}} when is_list(errors) ->
        {:error, [Enum.join(errors)]}
    end
  end

  defp calculate_count(nil, _), do: {:ok, 1}
  defp calculate_count(count, _) when is_integer(count), do: {:ok, count}

  defp calculate_count(expression, vars) when is_binary(expression) do
    expression =
      Enum.reduce(
        vars,
        expression,
        fn {var, value}, expr ->
          String.replace(expr, Atom.to_string(var), Integer.to_string(value), global: true)
        end
      )

    Abacus.eval(expression)
  end
end
