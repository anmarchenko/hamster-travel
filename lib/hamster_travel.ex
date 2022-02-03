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
        }
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
        }
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
        }
      },
      %{
        id: 4,
        name: "Копенгаген и немного Швеции",
        slug: "kopengagen-i-nemnogo-shvetsii",
        duration: 4,
        start_date: ~D[2019-05-16],
        status: "finished",
        countries: ["dk", "se", "fi", "fo"],
        people_count: 3,
        cover:
          "https://images.unsplash.com/photo-1643288939906-5c6c60c9d289?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=3432&q=80",
        budget: Decimal.new("1171.76"),
        currency: "EUR",
        currency_symbol: "€",
        author: %{
          name: "Yulia Marchenko",
          avatar_url: "https://d2fetf4i8a4kn6.cloudfront.net/2014/09/30/11/27/53/320/foto.png"
        }
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
        }
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
        }
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

  def fetch_budget(_, _) do
    Decimal.new(:rand.uniform(1000))
  end
end
