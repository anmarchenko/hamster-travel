defmodule HamsterTravelWeb.BrowserTest do
  use HamsterTravelWeb.ConnCase

  import HamsterTravel.AccountsFixtures
  import HamsterTravel.PlanningFixtures

  alias HamsterTravel.Planning
  alias HamsterTravelWeb.Endpoint

  @moduletag :e2e
  @moduletag timeout: 150_000
  @moduletag capture_log: true

  defmodule Server do
    @behaviour Plug

    @impl Plug
    def init(upload_root) do
      Plug.Static.init(at: "/uploads", from: Path.join(upload_root, "uploads"))
    end

    @impl Plug
    def call(conn, static_options) do
      case Plug.Static.call(conn, static_options) do
        %Plug.Conn{halted: true} = conn -> conn
        conn -> Endpoint.call(conn, [])
      end
    end
  end

  test "Chromium trip workflows" do
    user = user_fixture()
    cover_trip = trip_fixture(user, %{name: "Cover E2E"})
    offline_trip = trip_fixture(user, %{name: "Offline E2E"})
    notes_trip = trip_fixture(user, %{name: "Offline Notes E2E"})

    note_fixture(%{
      trip_id: notes_trip.id,
      title: "Packing",
      text: "<p><strong>Bring tickets</strong></p>"
    })

    note_fixture(%{trip_id: notes_trip.id, title: "Food", text: "<p>Visit the market</p>"})
    recovery_trip = trip_fixture(user, %{name: "Recovery E2E"})
    existing_expense = day_expense_fixture(%{trip_id: recovery_trip.id})
    pdf_trip = trip_fixture(user, %{name: "PDF E2E"})
    sheet_trip = trip_fixture(user, %{name: "Expense Sheet E2E"})
    mobile_sheet_trip = trip_fixture(user, %{name: "Mobile Expense Sheet E2E", currency: "USD"})
    food = Planning.get_food_budget_category!(sheet_trip)
    {:ok, _other} = Planning.create_budget_category(sheet_trip, %{name: "Other"})

    for {currency, amount} <- [{:EUR, 7}, {:EUR, 11}, {:USD, 22}, {:EUR, 17}, {:EUR, 20}] do
      {:ok, _expense} =
        Planning.create_budget_category_actual_expense(food, %{price: Money.new(currency, amount)})
    end

    base_url = start_browser_server!()

    {output, status} =
      System.cmd("npm", ["test"],
        cd: __DIR__,
        stderr_to_stdout: true,
        env: [
          {"E2E_BASE_URL", base_url},
          {"E2E_EMAIL", user.email},
          {"E2E_PASSWORD", valid_user_password()},
          {"E2E_COVER_TRIP", cover_trip.slug},
          {"E2E_OFFLINE_TRIP", offline_trip.slug},
          {"E2E_NOTES_TRIP", notes_trip.slug},
          {"E2E_RECOVERY_TRIP", recovery_trip.slug},
          {"E2E_PDF_TRIP", pdf_trip.slug},
          {"E2E_SHEET_TRIP", sheet_trip.slug},
          {"E2E_MOBILE_SHEET_TRIP", mobile_sheet_trip.slug}
        ]
      )

    assert status == 0, output
    IO.write(output)
    assert %{file_name: "phone.HEIC"} = Planning.get_trip!(cover_trip.id).cover
    assert Planning.get_trip!(offline_trip.id).name == "Offline E2E updated"

    assert [recovered_expense] =
             recovery_trip
             |> Planning.list_day_expenses()
             |> Enum.reject(&(&1.id == existing_expense.id))

    assert recovered_expense.name == "Airport bus"
    assert recovered_expense.expense.price == Money.new(:EUR, "12.50")
  end

  defp start_browser_server! do
    upload_root = Path.join(System.tmp_dir!(), "hamster-travel-e2e-#{Ecto.UUID.generate()}")
    File.mkdir!(upload_root)
    on_exit(fn -> File.rm_rf!(upload_root) end)

    http_options = Keyword.merge(Endpoint.config(:http), plug: {Server, upload_root}, port: 0)
    server = start_supervised!({Bandit, http_options})
    {:ok, {{127, 0, 0, 1}, port}} = ThousandIsland.listener_info(server)
    base_url = "http://localhost:#{port}"

    put_test_env(:waffle, :storage_dir_prefix, upload_root)
    put_test_env(:waffle, :asset_host, base_url)
    put_test_env(:hamster_travel, :waffle_skip_processing, false)

    base_url
  end

  defp put_test_env(app, key, value) do
    previous = Application.fetch_env(app, key)
    Application.put_env(app, key, value)

    on_exit(fn ->
      case previous do
        {:ok, old_value} -> Application.put_env(app, key, old_value)
        :error -> Application.delete_env(app, key)
      end
    end)
  end
end
