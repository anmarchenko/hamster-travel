defmodule HamsterTravel.Repo.Migrations.CorrectImportedHufExpenses do
  use Ecto.Migration

  @trip_name "Будапешт и Тапольца"
  @start_date "2021-09-07"
  @end_date "2021-09-14"

  def up do
    adjust_huf_amounts("* 100")
  end

  def down do
    adjust_huf_amounts("/ 100")
  end

  defp adjust_huf_amounts(operator) do
    execute("""
    UPDATE expenses AS e
    SET price = ROW((e.price).currency_code, (e.price).amount #{operator})::money_with_currency
    FROM trips AS t
    WHERE e.trip_id = t.id
      AND t.currency = 'HUF'
      AND t.name = '#{@trip_name}'
      AND t.start_date = DATE '#{@start_date}'
      AND t.end_date = DATE '#{@end_date}'
      AND (e.price).currency_code = 'HUF'
    """)

    execute("""
    UPDATE food_expenses AS f
    SET price_per_day =
      ROW((f.price_per_day).currency_code, (f.price_per_day).amount #{operator})::money_with_currency
    FROM trips AS t
    WHERE f.trip_id = t.id
      AND t.currency = 'HUF'
      AND t.name = '#{@trip_name}'
      AND t.start_date = DATE '#{@start_date}'
      AND t.end_date = DATE '#{@end_date}'
      AND (f.price_per_day).currency_code = 'HUF'
    """)
  end
end
