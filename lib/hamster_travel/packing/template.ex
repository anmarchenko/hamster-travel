defmodule HamsterTravel.Packing.Template do
  require Logger

  alias HamsterTravel.Packing.{Item, List}
  alias HamsterTravel.Result

  @doc """
  Parses YAML template from the provided file and converts it to the list of
  backpack lists.
  """
  def execute(template, vars \\ %{})
  def execute(nil, _), do: []

  @spec execute(String.t(), map()) :: {:ok, list(List)} | {:error, list(String.t())}
  def execute(template, vars) do
    filepath = Application.app_dir(:hamster_travel, "priv/templates/#{template}.yml")

    case YamlElixir.read_from_file(filepath) do
      {:ok, %{"backpack" => lists}} ->
        lists
        |> Enum.map(fn list -> parse_list(list, vars) end)
        |> Result.list_or_errors()
        |> fill_ranks()

      {:error, %{message: message}} ->
        {:error, [message]}

      {:error, error} when is_binary(error) ->
        {:error, [error]}

      _ ->
        {:error, ["invalid template format"]}
    end
  end

  def from_changeset(
        %Ecto.Changeset{changes: %{template: template, days: days, nights: nights}} = changeset
      )
      when template != nil do
    case execute(template, %{days: days, nights: nights}) do
      {:ok, lists} ->
        changeset
        |> Ecto.Changeset.put_assoc(:lists, lists)

      {:error, messages} ->
        Logger.warning(
          "[HamsterTravel.Packing] Template #{template} could not be parsed. Errors were: #{inspect(messages)} "
        )

        changeset
    end
  end

  def from_changeset(changeset), do: changeset

  defp parse_list(nil, _), do: %List{}

  defp parse_list(list_map, vars) do
    case parse_items(list_map["items"], vars) do
      {:ok, items} ->
        %List{
          name: list_map["name"],
          items: items
        }

      {:error, _} = error_tuple ->
        error_tuple
    end
  end

  defp parse_items(nil, _), do: {:ok, []}
  defp parse_items([], _), do: {:ok, []}

  defp parse_items(items, vars) when is_list(items) do
    items
    |> Enum.map(fn item -> parse_item(item, vars) end)
    |> Enum.filter(fn res -> res != nil end)
    |> Result.list_or_errors()
    |> fill_ranks()
  end

  defp parse_item(nil, _), do: %Item{}

  defp parse_item(item, vars) do
    case calculate_count(item["count"], vars) do
      {:ok, 0} ->
        nil

      {:ok, num} ->
        %Item{
          name: item["name"],
          count: num
        }

      {:error, %{description: description}} ->
        {:error, [description]}

      {:error, {_, :new_parser, errors}} when is_list(errors) ->
        {:error, [Enum.join(errors)]}
    end
  end

  defp calculate_count(nil, _), do: {:ok, 1}
  defp calculate_count(count, _) when is_integer(count), do: {:ok, count}

  defp calculate_count(expression, vars) when is_binary(expression) do
    case unknown_identifiers(expression, vars) do
      [] ->
        evaluate_expression(expression, vars)

      unknown ->
        {:error, %{description: "unknown variables: #{Enum.join(unknown, ", ")}"}}
    end
  end

  defp evaluate_expression(expression, vars) do
    expression =
      Enum.reduce(
        vars,
        expression,
        fn {var, value}, expr ->
          String.replace(expr, Atom.to_string(var), Integer.to_string(value), global: true)
        end
      )

    case Abacus.eval(expression) do
      {:ok, float_num} when is_float(float_num) ->
        {:ok, round(float_num)}

      rest ->
        rest
    end
  end

  defp unknown_identifiers(expression, vars) do
    expression
    |> extract_identifiers()
    |> Enum.reject(&(&1 in allowed_identifiers(vars)))
    |> Enum.uniq()
  end

  defp extract_identifiers(expression) do
    Regex.scan(~r/\b[a-zA-Z_][a-zA-Z0-9_]*\b/, expression)
    |> Enum.flat_map(& &1)
  end

  defp allowed_identifiers(vars) do
    vars =
      vars
      |> Map.keys()
      |> Enum.map(&to_string/1)

    defaults =
      Abacus.Runtime.Scope.default_scope()
      |> Map.keys()
      |> Enum.map(&Atom.to_string/1)

    vars ++ defaults ++ ["true", "false", "null"]
  end

  defp fill_ranks({:ok, list}) do
    {:ok, HamsterTravel.EctoOrdered.fill_ranks(list)}
  end

  defp fill_ranks(rest), do: rest
end
