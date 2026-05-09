defmodule HamsterTravel.LegacyImport.AccommodationsSquasher do
  @moduledoc """
  Squashes legacy per-day accommodations into contiguous ranges in each trip.

  Consecutive accommodations with the same normalized name are merged by:
  - keeping the first accommodation row
  - extending its `start_day`/`end_day` to the full contiguous span
  - merging all group accommodation expenses into one expense linked to the kept row
  - deleting redundant accommodations and redundant group expenses

  The task enforces a per-trip accommodation budget sanity check:
  total accommodation expense per currency must stay unchanged.
  """

  import Ecto.Query, warn: false

  alias Decimal, as: D
  alias HamsterTravel.Planning.{Accommodation, Expense, Trip}
  alias HamsterTravel.Repo
  alias Money

  @type options :: [
          dry_run: boolean()
        ]

  @type run_result :: %{
          trips_total: non_neg_integer(),
          trips_changed: non_neg_integer(),
          groups_merged: non_neg_integer(),
          accommodations_deleted: non_neg_integer(),
          accommodations_updated: non_neg_integer(),
          expenses_deleted: non_neg_integer(),
          expenses_updated: non_neg_integer(),
          trips_failed: non_neg_integer(),
          failures: list(%{trip_id: binary(), trip_name: String.t(), reason: String.t()})
        }

  @spec run(options()) :: {:ok, run_result()}
  def run(opts \\ []) do
    dry_run = Keyword.get(opts, :dry_run, false)

    trips =
      from(t in Trip,
        select: %{id: t.id, name: t.name},
        order_by: [asc: t.inserted_at, asc: t.id]
      )
      |> Repo.all()

    initial = %{
      trips_total: length(trips),
      trips_changed: 0,
      groups_merged: 0,
      accommodations_deleted: 0,
      accommodations_updated: 0,
      expenses_deleted: 0,
      expenses_updated: 0,
      trips_failed: 0,
      failures: []
    }

    result =
      Enum.reduce(trips, initial, fn trip, acc ->
        case process_trip(trip, dry_run) do
          {:ok, %{changed?: false}} ->
            acc

          {:ok, stats} ->
            %{
              acc
              | trips_changed: acc.trips_changed + 1,
                groups_merged: acc.groups_merged + stats.groups_merged,
                accommodations_deleted: acc.accommodations_deleted + stats.accommodations_deleted,
                accommodations_updated: acc.accommodations_updated + stats.accommodations_updated,
                expenses_deleted: acc.expenses_deleted + stats.expenses_deleted,
                expenses_updated: acc.expenses_updated + stats.expenses_updated
            }

          {:error, reason} ->
            failure = %{trip_id: trip.id, trip_name: trip.name || "", reason: reason}

            %{
              acc
              | trips_failed: acc.trips_failed + 1,
                failures: [failure | acc.failures]
            }
        end
      end)

    {:ok, %{result | failures: Enum.reverse(result.failures)}}
  end

  defp process_trip(%{id: trip_id, name: trip_name}, dry_run) do
    case fetch_trip_accommodations(trip_id) do
      [_ | [_ | _]] = accommodations ->
        process_trip_accommodations(accommodations, trip_id, trip_name, dry_run)

      _ ->
        {:ok, %{changed?: false}}
    end
  end

  defp fetch_trip_accommodations(trip_id) do
    from(a in Accommodation,
      where: a.trip_id == ^trip_id,
      order_by: [asc: a.start_day, asc: a.end_day, asc: a.id]
    )
    |> Repo.all()
  end

  defp process_trip_accommodations(accommodations, trip_id, trip_name, dry_run) do
    expenses = fetch_accommodation_expenses(trip_id, accommodations)
    expenses_by_acc_id = Enum.group_by(expenses, & &1.accommodation_id)

    case merge_groups(accommodations) do
      [] ->
        {:ok, %{changed?: false}}

      groups ->
        plans = Enum.map(groups, &build_group_plan(&1, expenses_by_acc_id))
        process_merge_plans(trip_id, trip_name, expenses, plans, dry_run)
    end
  end

  defp fetch_accommodation_expenses(trip_id, accommodations) do
    acc_ids = Enum.map(accommodations, & &1.id)

    from(e in Expense,
      where: e.trip_id == ^trip_id and e.accommodation_id in ^acc_ids,
      order_by: [asc: e.id]
    )
    |> Repo.all()
  end

  defp process_merge_plans(trip_id, trip_name, expenses, plans, dry_run) do
    before_totals = totals_by_currency(expenses)
    projected_totals = projected_totals_after_plans(expenses, plans)

    if totals_equal?(before_totals, projected_totals) do
      log_trip_plan(trip_id, trip_name, plans, dry_run)
      finish_trip_merge(trip_id, trip_name, before_totals, plans, dry_run)
    else
      {:error,
       "sanity check failed before applying changes: projected totals differ (before=#{format_totals(before_totals)} projected=#{format_totals(projected_totals)})"}
    end
  end

  defp finish_trip_merge(trip_id, trip_name, before_totals, plans, true) do
    print_line(
      "[DRY-RUN][TRIP] #{trip_label(trip_id, trip_name)} sanity check OK: accommodation totals #{format_totals(before_totals)}"
    )

    {:ok, stats_for_plans(plans)}
  end

  defp finish_trip_merge(trip_id, trip_name, before_totals, plans, false) do
    case apply_merge_plans(trip_id, before_totals, plans) do
      {:ok, after_totals} ->
        print_line(
          "[APPLY][TRIP] #{trip_label(trip_id, trip_name)} sanity check OK: accommodation totals #{format_totals(after_totals)}"
        )

        {:ok, stats_for_plans(plans)}

      {:error, reason} ->
        {:error, format_error(reason)}
    end
  end

  defp apply_merge_plans(trip_id, before_totals, plans) do
    Repo.transaction(fn ->
      Enum.each(plans, &apply_plan!/1)

      after_expenses =
        from(e in Expense,
          where: e.trip_id == ^trip_id and not is_nil(e.accommodation_id),
          select: e
        )
        |> Repo.all()

      after_totals = totals_by_currency(after_expenses)

      unless totals_equal?(before_totals, after_totals) do
        Repo.rollback(
          "sanity check failed after apply: before=#{format_totals(before_totals)} after=#{format_totals(after_totals)}"
        )
      end

      after_totals
    end)
  end

  defp stats_for_plans(plans) do
    %{
      changed?: true,
      groups_merged: length(plans),
      accommodations_deleted: Enum.sum(Enum.map(plans, &length(&1.delete_accommodation_ids))),
      accommodations_updated: length(plans),
      expenses_deleted: Enum.sum(Enum.map(plans, &length(&1.delete_expense_ids))),
      expenses_updated: Enum.count(plans, & &1.update_expense?)
    }
  end

  defp merge_groups(accommodations) do
    {groups, current_group} =
      Enum.reduce(accommodations, {[], []}, fn acc, {groups_acc, current} ->
        case current do
          [] ->
            {groups_acc, [acc]}

          [prev | _] = current_group ->
            last = List.last(current_group)

            if same_name?(prev.name, acc.name) and acc.start_day == last.end_day + 1 do
              {groups_acc, current_group ++ [acc]}
            else
              {groups_acc ++ [current_group], [acc]}
            end
        end
      end)

    all_groups =
      case current_group do
        [] -> groups
        _ -> groups ++ [current_group]
      end

    Enum.filter(all_groups, fn group -> length(group) > 1 end)
  end

  defp build_group_plan(group, expenses_by_acc_id) do
    keep = hd(group)
    duplicates = tl(group)

    keep_start_day = keep.start_day
    keep_end_day = List.last(group).end_day

    group_accommodation_ids = Enum.map(group, & &1.id)

    group_expenses =
      group_accommodation_ids
      |> Enum.flat_map(fn acc_id -> Map.get(expenses_by_acc_id, acc_id, []) end)
      |> Enum.sort_by(& &1.id)

    keeper_expense =
      group_expenses
      |> Enum.find(fn expense -> expense.accommodation_id == keep.id end)
      |> case do
        nil -> List.first(group_expenses)
        expense -> expense
      end

    merged_expense_price =
      case group_expenses do
        [] ->
          nil

        [first | rest] ->
          Enum.reduce(rest, first.price, fn expense, sum ->
            Money.add!(sum, expense.price)
          end)
      end

    delete_expense_ids =
      group_expenses
      |> Enum.reject(fn expense ->
        case keeper_expense do
          nil -> true
          kept -> expense.id == kept.id
        end
      end)
      |> Enum.map(& &1.id)

    %{
      keep: keep,
      keep_new_start_day: keep_start_day,
      keep_new_end_day: keep_end_day,
      delete_accommodation_ids: Enum.map(duplicates, & &1.id),
      duplicates: duplicates,
      keeper_expense: keeper_expense,
      merged_expense_price: merged_expense_price,
      delete_expense_ids: delete_expense_ids,
      update_expense?: not is_nil(keeper_expense) and not is_nil(merged_expense_price)
    }
  end

  defp projected_totals_after_plans(expenses, plans) do
    plans_by_expense_id =
      Enum.reduce(plans, %{}, fn plan, acc ->
        case plan.keeper_expense do
          nil ->
            acc

          keeper ->
            Map.put(acc, keeper.id, plan)
        end
      end)

    delete_ids =
      plans
      |> Enum.flat_map(& &1.delete_expense_ids)
      |> MapSet.new()

    expenses
    |> Enum.reduce([], fn expense, acc ->
      cond do
        MapSet.member?(delete_ids, expense.id) ->
          acc

        Map.has_key?(plans_by_expense_id, expense.id) ->
          plan = Map.fetch!(plans_by_expense_id, expense.id)
          [%{expense | price: plan.merged_expense_price} | acc]

        true ->
          [expense | acc]
      end
    end)
    |> totals_by_currency()
  end

  defp apply_plan!(plan) do
    keep = plan.keep

    keep
    |> Accommodation.changeset(%{
      start_day: plan.keep_new_start_day,
      end_day: plan.keep_new_end_day
    })
    |> Repo.update!()

    case plan.keeper_expense do
      nil ->
        :ok

      keeper_expense ->
        if keeper_expense.accommodation_id != keep.id do
          keeper_expense
          |> Ecto.Changeset.change(accommodation_id: keep.id)
          |> Repo.update!()
        end

        keeper_expense
        |> Ecto.Changeset.change(price: plan.merged_expense_price)
        |> Repo.update!()
    end

    if plan.delete_expense_ids != [] do
      from(e in Expense, where: e.id in ^plan.delete_expense_ids)
      |> Repo.delete_all()
    end

    if plan.delete_accommodation_ids != [] do
      from(a in Accommodation, where: a.id in ^plan.delete_accommodation_ids)
      |> Repo.delete_all()
    end

    :ok
  end

  defp totals_by_currency(expenses) do
    Enum.reduce(expenses, %{}, fn expense, acc ->
      case expense.price do
        %Money{currency: currency, amount: amount} ->
          Map.update(acc, currency, amount, &D.add(&1, amount))

        _ ->
          acc
      end
    end)
  end

  defp totals_equal?(left, right) do
    keys = Map.keys(left) |> Enum.concat(Map.keys(right)) |> Enum.uniq()

    Enum.all?(keys, fn key ->
      left_amount = Map.get(left, key, D.new("0"))
      right_amount = Map.get(right, key, D.new("0"))
      D.equal?(left_amount, right_amount)
    end)
  end

  defp format_totals(totals) do
    totals
    |> Enum.sort_by(fn {currency, _} -> to_string(currency) end)
    |> Enum.map_join(", ", fn {currency, amount} ->
      "#{currency}=#{D.to_string(amount, :normal)}"
    end)
  end

  defp same_name?(left, right) do
    normalize_name(left) == normalize_name(right)
  end

  defp normalize_name(name) when is_binary(name), do: name |> String.trim() |> String.downcase()
  defp normalize_name(_), do: ""

  defp log_trip_plan(trip_id, trip_name, plans, dry_run) do
    prefix = if dry_run, do: "[DRY-RUN]", else: "[APPLY]"

    print_line(
      "#{prefix}[TRIP] #{trip_label(trip_id, trip_name)}: #{length(plans)} merge group(s)"
    )

    Enum.each(plans, fn plan ->
      keep = plan.keep

      print_line(
        "#{prefix}[UPDATE] keep accommodation ##{keep.id} \"#{keep.name}\" days #{keep.start_day}-#{keep.end_day} -> #{plan.keep_new_start_day}-#{plan.keep_new_end_day}"
      )

      if plan.keeper_expense && plan.merged_expense_price do
        kept = plan.keeper_expense

        print_line(
          "#{prefix}[UPDATE] keep expense ##{kept.id} (accommodation ##{kept.accommodation_id}) price -> #{inspect(plan.merged_expense_price)}"
        )
      end

      Enum.each(plan.delete_expense_ids, fn expense_id ->
        print_line("#{prefix}[DELETE] expense ##{expense_id}")
      end)

      Enum.each(plan.duplicates, fn duplicate ->
        print_line(
          "#{prefix}[DELETE] accommodation ##{duplicate.id} \"#{duplicate.name}\" days #{duplicate.start_day}-#{duplicate.end_day}"
        )
      end)
    end)
  end

  defp trip_label(trip_id, trip_name) do
    "##{trip_id} \"#{trip_name || ""}\""
  end

  defp format_error(%{message: message}) when is_binary(message), do: message
  defp format_error(reason) when is_binary(reason), do: reason
  defp format_error(reason), do: inspect(reason)

  defp print_line(line), do: IO.puts(line)
end
