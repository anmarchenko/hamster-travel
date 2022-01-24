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
        name: "Рождественский Стокгольм",
        duration: 4,
        start_date: ~D[2021-12-17],
        status: "planned",
        countries: ["se"],
        people_count: 3,
        cover:
          "https://d2fetf4i8a4kn6.cloudfront.net/2021/09/19/12/38/10/41fe55b1-aa9d-4798-9854-f57ce928ded0/photo.png",
        budget: Decimal.new("1124.59"),
        currency_symbol: "€",
        author: %{
          name: "Yulia Marchenko",
          avatar_url: "https://d2fetf4i8a4kn6.cloudfront.net/2014/09/30/11/27/53/320/foto.png"
        }
      },
      %{
        name: "Будапешт и Тапольца",
        duration: 8,
        start_date: ~D[2021-09-07],
        status: "finished",
        countries: ["hu"],
        people_count: 3,
        cover:
          "https://d2fetf4i8a4kn6.cloudfront.net/2017/02/10/17/38/23/f15ba329-31e3-4497-9caa-2ee2d7caf3e7/photo.png",
        budget: Decimal.new("1431.28"),
        currency_symbol: "€",
        author: %{
          name: "Yulia Marchenko",
          avatar_url: "https://d2fetf4i8a4kn6.cloudfront.net/2014/09/30/11/27/53/320/foto.png"
        }
      },
      %{
        name: "Мальорка",
        duration: 9,
        start_date: ~D[2021-07-13],
        status: "finished",
        countries: ["es"],
        people_count: 3,
        cover:
          "https://d2fetf4i8a4kn6.cloudfront.net/2021/06/08/11/27/25/98e26f12-b57a-4c8a-a380-5ca65109d214/photo.png",
        budget: Decimal.new("2939.65"),
        currency_symbol: "€",
        author: %{
          name: "Yulia Marchenko",
          avatar_url: "https://d2fetf4i8a4kn6.cloudfront.net/2014/09/30/11/27/53/320/foto.png"
        }
      },
      %{
        name: "Копенгаген и немного Швеции",
        duration: 4,
        start_date: ~D[2019-05-16],
        status: "finished",
        countries: ["dk", "se"],
        people_count: 3,
        cover:
          "https://d2fetf4i8a4kn6.cloudfront.net/2018/09/24/14/55/35/5016a1b2-2500-418f-8db1-97a8a229f4a2/photo.png",
        budget: Decimal.new("1171.76"),
        currency_symbol: "€",
        author: %{
          name: "Yulia Marchenko",
          avatar_url: "https://d2fetf4i8a4kn6.cloudfront.net/2014/09/30/11/27/53/320/foto.png"
        }
      }
    ]
  end
end
