defmodule HamsterTravelWeb.Planning.BudgetExpenseSheet do
  @moduledoc false

  use Gettext, backend: HamsterTravelWeb.Gettext

  alias HamsterTravelWeb.Cldr

  def snapshot(category, display_currency, can_edit) do
    %{
      currency: display_currency,
      trip_currency: category.trip.currency,
      can_edit: can_edit,
      expenses: Enum.map(category.actual_expenses, &expense_data(&1, display_currency))
    }
  end

  def changes(%{"mode" => mode, "cells" => [_ | _] = cells} = params, display_currency)
      when mode in ["add", "append", "edit", "replace", "delete"] and length(cells) <= 100 do
    if mode in ["add", "edit"] and length(cells) != 1 do
      {:error, :invalid_cells}
    else
      with {:ok, opts} <- append_options(mode, params),
           {:ok, changes} <- parse_cells(cells, mode, display_currency) do
        {:ok, changes, opts}
      end
    end
  end

  def changes(_params, _display_currency), do: {:error, :invalid_cells}

  def error_message(:unauthorized), do: gettext("Only trip participants can edit this trip.")

  def error_message(:invalid_amount),
    do: gettext("Enter a positive amount using digits and a decimal separator.")

  def error_message(:wrong_currency), do: gettext("Edit this amount in its original currency.")
  def error_message(:stale_expense), do: gettext("This expense is no longer available.")

  def error_message(:stale_append),
    do: gettext("The expense list changed. Reopen the add cell before trying again.")

  def error_message({:stale_expense, money}) do
    gettext("This expense changed to %{amount}. Cancel and reopen it to edit the current value.",
      amount: Cldr.format_money(money.amount, money.currency)
    )
  end

  def error_message(_reason), do: gettext("Could not save actual expenses.")

  def labels do
    %{
      add: gettext("Add expense"),
      amount_in: gettext("Amount in %{currency}", currency: "{currency}"),
      original: gettext("Original amount: %{amount}", amount: "{amount}"),
      add_in: gettext("New expense in %{currency}", currency: "{currency}"),
      range: gettext("%{range} selected", range: "{range}"),
      saving: gettext("Saving…"),
      disconnected: gettext("Connection interrupted. Check the saved values before retrying."),
      paste_too_large: gettext("Paste up to 100 amounts at a time."),
      paste_outside: gettext("Paste must fit existing cells. Paste into + to append expenses."),
      delete_too_large: gettext("Select up to 100 expenses to delete at a time."),
      unavailable_conversion: gettext("This amount could not be converted for copying."),
      paste_count: gettext("Amounts to add: %{count}", count: "{count}")
    }
  end

  defp expense_data(expense, display_currency) do
    {display, original, converted?} =
      Cldr.convert_money_for_display(expense.price, display_currency)

    locale = Gettext.get_locale(HamsterTravelWeb.Gettext)

    %{
      id: to_string(expense.id),
      currency: to_string(original.currency),
      expected: Decimal.to_string(original.amount, :normal),
      input: Cldr.format_money_input(original.amount, locale),
      original: Cldr.format_money(original.amount, original.currency),
      display: Cldr.format_money(display.amount, display.currency),
      converted: converted?,
      copy: copy_amount(display, display_currency, locale)
    }
  end

  defp copy_amount(%Money{currency: currency} = money, display_currency, locale) do
    if to_string(currency) == display_currency do
      money = Money.round(money)
      Cldr.format_money_input(money.amount, locale)
    end
  end

  defp parse_cells(cells, mode, display_currency) do
    cells
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {cell, index}, {:ok, parsed} ->
      case parse_cell(cell, mode, display_currency) do
        {:ok, cell} -> {:cont, {:ok, [cell | parsed]}}
        {:error, reason} -> {:halt, {:error, {index, reason}}}
      end
    end)
    |> case do
      {:ok, cells} -> {:ok, Enum.reverse(cells)}
      error -> error
    end
  end

  defp append_options(mode, _params) when mode in ["edit", "replace", "delete"], do: {:ok, []}
  defp append_options(_mode, %{"tail" => nil}), do: {:ok, [expected_tail: nil]}

  defp append_options(_mode, %{"tail" => tail}) do
    with {:ok, id} <- expense_id(tail), do: {:ok, [expected_tail: id]}
  end

  defp append_options(_mode, _params), do: {:error, :invalid_cells}

  defp parse_cell(%{"amount" => amount, "currency" => currency}, mode, _display_currency)
       when mode in ["add", "append"] do
    with {:ok, price} <- price(amount, currency, mode == "append"),
         true <- Money.positive?(price) do
      {:ok, %{price: price}}
    else
      _ -> {:error, :invalid_amount}
    end
  end

  defp parse_cell(
         %{"id" => id, "expected" => expected, "expected_currency" => expected_currency} = cell,
         mode,
         display_currency
       )
       when mode in ["edit", "replace", "delete"] do
    with {:ok, id} <- expense_id(id),
         {:ok, expected} <- expected_price(expected, expected_currency),
         {:ok, price} <- changed_price(mode, cell),
         :ok <- paste_currency(mode, price, expected, display_currency) do
      {:ok, %{id: id, expected: expected, price: price}}
    end
  end

  defp parse_cell(_cell, _mode, _display_currency), do: {:error, :invalid_cells}

  defp expense_id(id) when is_binary(id) and byte_size(id) <= 19 do
    case Integer.parse(id) do
      {id, ""} when id > 0 and id <= 9_223_372_036_854_775_807 -> {:ok, id}
      _ -> {:error, :invalid_cells}
    end
  end

  defp expense_id(_id), do: {:error, :invalid_cells}

  defp changed_price("delete", _cell), do: {:ok, nil}

  defp changed_price(mode, %{"amount" => amount, "currency" => currency})
       when is_binary(amount) and byte_size(amount) <= 80 do
    case {mode, String.trim(amount)} do
      {"edit", ""} ->
        {:ok, nil}

      {mode, amount} ->
        with {:ok, price} <- price(amount, currency, mode == "replace") do
          {:ok, if(Money.zero?(price), do: nil, else: price)}
        end
    end
  end

  defp changed_price(_mode, _cell), do: {:error, :invalid_cells}

  defp paste_currency("replace", %Money{} = price, expected, display_currency) do
    if to_string(expected.currency) == display_currency and expected.currency == price.currency do
      :ok
    else
      {:error, :wrong_currency}
    end
  end

  defp paste_currency(_mode, _price, _expected, _display_currency), do: :ok

  defp expected_price(amount, currency)
       when is_binary(amount) and byte_size(amount) <= 80 do
    if Regex.match?(~r/^-?[0-9]+(?:\.[0-9]+)?$/, amount) do
      build_price(amount, currency)
    else
      {:error, :invalid_cells}
    end
  end

  defp expected_price(_amount, _currency), do: {:error, :invalid_cells}

  defp price(raw, currency, grouped?) when is_binary(raw) and byte_size(raw) <= 80 do
    raw = String.trim(raw)
    locale = Gettext.get_locale(HamsterTravelWeb.Gettext)

    cond do
      Regex.match?(~r/^[0-9]{1,3}(?:,[0-9]{3})+(?:\.[0-9]+)?$/, raw) and locale == "en" and
          grouped? ->
        build_price(String.replace(raw, ",", ""), currency)

      Regex.match?(
        ~r/^(?:[0-9]+|[0-9]{1,3}(?:[ \x{00A0}\x{202F}][0-9]{3})+)(?:[.,][0-9]+)?$/u,
        raw
      ) ->
        normalized =
          raw |> String.replace(~r/[ \x{00A0}\x{202F}]/u, "") |> String.replace(",", ".")

        build_price(normalized, currency)

      true ->
        {:error, :invalid_amount}
    end
  end

  defp price(_raw, _currency, _grouped?), do: {:error, :invalid_amount}

  defp build_price(amount, currency) when is_binary(currency) and byte_size(currency) <= 16 do
    with {decimal, ""} <- Decimal.parse(amount),
         %Money{} = money <- Money.new(currency, decimal) do
      {:ok, money}
    else
      _ -> {:error, :invalid_amount}
    end
  end

  defp build_price(_amount, _currency), do: {:error, :invalid_amount}
end
