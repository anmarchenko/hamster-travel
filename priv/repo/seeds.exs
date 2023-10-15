# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     HamsterTravel.Repo.insert!(%HamsterTravel.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

bunny =
  HamsterTravel.Repo.insert!(%HamsterTravel.Accounts.User{
    name: "Bunny Hamsters",
    email: "bunny@hamsters.test",
    confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    hashed_password: Bcrypt.hash_pwd_salt("test1234"),
    locale: "ru"
  })

hamster =
  HamsterTravel.Repo.insert!(%HamsterTravel.Accounts.User{
    name: "Hamster Hamsters",
    email: "hamster@hamsters.test",
    confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    hashed_password: Bcrypt.hash_pwd_salt("test1234"),
    locale: "en"
  })

john =
  HamsterTravel.Repo.insert!(%HamsterTravel.Accounts.User{
    name: "John Doe",
    email: "john.doe@mail.test",
    confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    hashed_password: Bcrypt.hash_pwd_salt("test1234"),
    locale: "en"
  })

HamsterTravel.Social.add_friends(bunny.id, hamster.id)

HamsterTravel.Packing.create_backpack(
  %{template: "hamsters", name: "Италия", days: 14, nights: 13},
  bunny
)

HamsterTravel.Packing.create_backpack(
  %{template: "hamsters", name: "USA", days: 20, nights: 19},
  hamster
)

HamsterTravel.Packing.create_backpack(
  %{template: "hamsters", name: "Выходные в горах", days: 2, nights: 1},
  bunny
)

HamsterTravel.Packing.create_backpack(
  %{name: "My trip", days: 5, nights: 4},
  john
)
