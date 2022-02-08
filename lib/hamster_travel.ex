defmodule HamsterTravel do
  @moduledoc """
  HamsterTravel keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def plans() do
    [
      %{
        id: 1,
        name: "Рождественский Стокгольм",
        slug: "rozhdestvenskiy-stokgolm",
        duration: 4,
        start_date: ~D[2021-12-17],
        status: "planned",
        countries: ["se"],
        people_count: 3,
        cover:
          "https://images.unsplash.com/photo-1572225303717-a96db5e8d8b0?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1887&q=80",
        budget: Decimal.new("1124.59"),
        currency: "EUR",
        currency_symbol: "€",
        author: %{
          name: "Yulia Marchenko",
          avatar_url: "https://d2fetf4i8a4kn6.cloudfront.net/2014/09/30/11/27/53/320/foto.png"
        },
        places: [
          %{
            id: 434_343,
            city: %{
              country: "se",
              name: "Стокгольм"
            },
            day_intervals: [[0, 3]]
          }
        ],
        transfers: []
      },
      %{
        id: 2,
        name: "Будапешт и Тапольца",
        slug: "budapesht-i-tapoltsa",
        duration: 8,
        start_date: ~D[2021-09-07],
        status: "finished",
        countries: ["hu"],
        people_count: 3,
        cover:
          "https://images.unsplash.com/photo-1549877452-9c387954fbc2?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=3870&q=80",
        budget: Decimal.new("1431.28"),
        currency: "EUR",
        currency_symbol: "€",
        author: %{
          name: "Yulia Marchenko",
          avatar_url: "https://d2fetf4i8a4kn6.cloudfront.net/2014/09/30/11/27/53/320/foto.png"
        },
        places: [],
        transfers: []
      },
      %{
        id: 3,
        name: "Мальорка",
        slug: "maljorka",
        duration: 9,
        start_date: ~D[2021-07-13],
        status: "finished",
        countries: ["es"],
        people_count: 3,
        cover:
          "https://images.unsplash.com/photo-1617093888347-f73de2649f94?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=3870&q=80",
        budget: Decimal.new("2939.65"),
        currency: "EUR",
        currency_symbol: "€",
        author: %{
          name: "Yulia Marchenko",
          avatar_url: "https://d2fetf4i8a4kn6.cloudfront.net/2014/09/30/11/27/53/320/foto.png"
        },
        places: [],
        transfers: []
      },
      %{
        id: 4,
        name: "Копенгаген и немного Швеции",
        slug: "kopengagen-i-nemnogo-shvetsii",
        duration: 4,
        start_date: ~D[2019-05-16],
        status: "finished",
        countries: ["dk", "se"],
        people_count: 3,
        cover:
          "https://images.unsplash.com/photo-1643288939906-5c6c60c9d289?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=3432&q=80",
        budget: Decimal.new("1171.76"),
        currency: "EUR",
        currency_symbol: "€",
        author: %{
          name: "Yulia Marchenko",
          avatar_url: "https://d2fetf4i8a4kn6.cloudfront.net/2014/09/30/11/27/53/320/foto.png"
        },
        places: [
          %{
            id: 32,
            city: %{
              country: "dk",
              name: "Копенгаген"
            },
            day_intervals: [[0, 3]]
          },
          %{
            id: 1,
            city: %{
              country: "se",
              name: "Мальмё"
            },
            day_intervals: [[2, 2]]
          },
          %{
            id: 2,
            city: %{
              country: "se",
              name: "Лунд"
            },
            day_intervals: [[2, 2]]
          }
        ],
        transfers: [
          %{
            day_index: 0,
            position: 0,
            type: "plane",
            station_from: "TXL",
            station_to: "CPN",
            time_from: "10:45",
            time_to: "11:55",
            city_from: %{
              name: "Берлин",
              country: "de"
            },
            city_to: %{
              name: "Копенгаген",
              country: "dk"
            },
            price: Decimal.new("85.06"),
            price_currency: "EUR",
            vehicle_id: nil,
            company: "Easyjet",
            comment: nil,
            links: [
              "https://www.easyjet.com/en"
            ]
          },
          %{
            day_index: 2,
            position: 0,
            type: "train",
            station_from: nil,
            station_to: "Centralstation",
            time_from: "08:47",
            time_to: "09:26",
            city_from: %{
              name: "Копенгаген",
              country: "dk"
            },
            city_to: %{
              name: "Мальмё",
              country: "se"
            },
            price: Decimal.new("182"),
            price_currency: "DKK",
            vehicle_id: "Re 1028",
            company: "DSB",
            comment: nil,
            links: []
          },
          %{
            day_index: 2,
            position: 1,
            type: "train",
            station_from: "Centralstation",
            station_to: "Centralstation",
            time_from: "12:11",
            time_to: "12:24",
            city_from: %{
              name: "Мальмё",
              country: "se"
            },
            city_to: %{
              name: "Лунд",
              country: "se"
            },
            price: Decimal.new("106"),
            price_currency: "SEK",
            vehicle_id: "1714",
            company: "Skånetrafiken",
            comment: nil,
            links: []
          },
          %{
            day_index: 2,
            position: 2,
            type: "train",
            station_from: "Centralstation",
            station_to: "H",
            time_from: "15:40",
            time_to: "16:28",
            city_from: %{
              name: "Лунд",
              country: "se"
            },
            city_to: %{
              name: "Копенгаген",
              country: "dk"
            },
            price: Decimal.new("300"),
            price_currency: "SEK",
            vehicle_id: "1714",
            company: "Skånetrafiken",
            comment: nil,
            links: []
          },
          %{
            day_index: 3,
            position: 0,
            type: "plane",
            station_from: "CPN",
            station_to: "TXL",
            time_from: "17:20",
            time_to: "18:20",
            city_from: %{
              name: "Копенгаген",
              country: "dk"
            },
            city_to: %{
              name: "Берлин",
              country: "de"
            },
            price: Decimal.new("70.14"),
            price_currency: "EUR",
            vehicle_id: nil,
            company: "Easyjet",
            comment: nil,
            links: [
              "https://www.easyjet.com/en"
            ]
          }
        ]
      }
    ]
  end

  def drafts() do
    [
      %{
        id: 5,
        name: "Бамберг - пивной город Франконии ",
        slug: "bamberg-pivnoy-gorod",
        duration: 3,
        start_date: nil,
        status: "draft",
        countries: ["de"],
        people_count: 2,
        cover:
          "https://images.unsplash.com/photo-1607338533044-c5bc1ec32bde?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1887&q=80",
        budget: Decimal.new("614.18"),
        currency: "EUR",
        currency_symbol: "€",
        author: %{
          name: "Yulia Marchenko",
          avatar_url: "https://d2fetf4i8a4kn6.cloudfront.net/2014/09/30/11/27/53/320/foto.png"
        },
        places: [],
        transfers: []
      },
      %{
        id: 6,
        name: "Гельголанд: в гости к тюленюшкам! ",
        slug: "gelgoland-v-gosti-k-tyul",
        duration: 2,
        start_date: nil,
        status: "draft",
        countries: ["de"],
        people_count: 1,
        cover:
          "https://images.unsplash.com/photo-1559157695-c3e284ea6c2b?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=3870&q=80",
        budget: Decimal.new("90"),
        currency: "EUR",
        currency_symbol: "€",
        author: %{
          name: "Yulia Marchenko",
          avatar_url: "https://d2fetf4i8a4kn6.cloudfront.net/2014/09/30/11/27/53/320/foto.png"
        },
        places: [],
        transfers: []
      }
    ]
  end

  def find_plan_by_slug(slug) do
    plan =
      Enum.find(plans() ++ drafts(), fn plan ->
        plan.slug == slug
      end)

    if plan != nil do
      {:ok, plan}
    else
      {:error, :not_found}
    end
  end

  def find_places_by_day(plan, day_index) do
    Enum.filter(plan.places, fn pl -> intersects_day(pl, day_index) end)
  end

  def find_transfers_by_day(plan, day_index) do
    plan.transfers
    |> Enum.filter(fn tr -> tr.day_index == day_index end)
    |> Enum.sort(fn l, r -> l.position <= r.position end)
  end

  def fetch_budget(_, _) do
    Decimal.new(:rand.uniform(1000))
  end

  defp intersects_day(item, day_index) do
    Enum.any?(item.day_intervals, fn [l, r] ->
      day_index >= l && day_index <= r
    end)
  end
end
