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

admin1 =
  HamsterTravel.Repo.insert!(%HamsterTravel.Accounts.User{
    name: "Test Admin",
    email: "admin@mail.test",
    confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    hashed_password: Bcrypt.hash_pwd_salt("test1234"),
    locale: "ru"
  })

admin2 =
  HamsterTravel.Repo.insert!(%HamsterTravel.Accounts.User{
    name: "Test Admin 2",
    email: "admin2@mail.test",
    confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    hashed_password: Bcrypt.hash_pwd_salt("test1234"),
    locale: "en"
  })

HamsterTravel.Repo.insert!(%HamsterTravel.Accounts.User{
  name: "Test Admin 3",
  email: "admin3@mail.test",
  confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
  hashed_password: Bcrypt.hash_pwd_salt("test1234"),
  locale: "en"
})

HamsterTravel.Social.add_friends(admin1.id, admin2.id)
