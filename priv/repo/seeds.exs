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

HamsterTravel.Repo.insert!(%HamsterTravel.Accounts.User{
  name: "Test Admin",
  email: "admin@mail.test",
  confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
  hashed_password: Bcrypt.hash_pwd_salt("test1234"),
  locale: "ru"
})
